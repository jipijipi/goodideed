// NOEXC Variant Generator CLI (scaffold)
//
// Generates semantic content variants for a single message's contentKey.
// - Input: --sequence <id> --message <id> (or --list <file>)
// - Config: tool/variants_config.json (override with --config <path>)
// - Output: Appends lines to assets/content/... target file (append-only). Creates file if missing.
// - Archive: Writes a full archive record under tool/ai_archive/YYYY/MM/DD/
// - LLM: Remote REST via HttpClient (provider-agnostic schema). Supports mock mode for dry-runs.
//
// Notes:
// - This is a dev tool; not part of the runtime app.
// - No legacy variants are read or written (assets/variants is ignored).

import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  final cli = _Cli.parse(args);
  if (cli.showHelp) {
    _printHelp();
    exit(0);
  }

  final config = await _Config.load(cli.configPath);

  final targets = <_Target>[];
  if (cli.listPath != null) {
    targets.addAll(await _loadTargetsFromList(cli.listPath!));
  } else if (cli.sequenceId != null && cli.messageId != null) {
    targets.add(_Target(cli.sequenceId!, cli.messageId!));
  } else {
    stderr.writeln('ERROR: Provide --sequence and --message, or --list <file>.');
    _printHelp();
    exit(2);
  }

  int success = 0;
  int failures = 0;

  for (final t in targets) {
    stdout.writeln('→ Processing ${t.sequenceId}:${t.messageId}');
    try {
      final result = await _processTarget(t, config, cli.writeMode);
      stdout.writeln('   Generated ${result.acceptedVariants.length} variants');
      success++;
    } catch (e, st) {
      stderr.writeln('   FAILED: $e');
      if (config.io.verbose) {
        stderr.writeln(st);
      }
      failures++;
      if (config.io.failFast) break;
    }
  }

  stdout.writeln('\nDone. ok=$success fail=$failures');
  if (failures > 0) exitCode = 1;
}

// ---------------- CLI ----------------

class _Cli {
  final String? sequenceId;
  final int? messageId;
  final String? listPath;
  final String configPath;
  final bool writeMode;
  final bool showHelp;

  _Cli({
    this.sequenceId,
    this.messageId,
    this.listPath,
    required this.configPath,
    required this.writeMode,
    required this.showHelp,
  });

  static _Cli parse(List<String> args) {
    String? sequenceId;
    int? messageId;
    String? listPath;
    String configPath = 'tool/variants_config.yaml';
    bool write = false;
    bool help = false;

    for (int i = 0; i < args.length; i++) {
      final a = args[i];
      switch (a) {
        case '--sequence':
          sequenceId = _next(args, ++i, '--sequence');
          break;
        case '--message':
          final raw = _next(args, ++i, '--message');
          messageId = int.tryParse(raw ?? '') ??
              (throw ArgumentError('Invalid --message value: $raw'));
          break;
        case '--list':
          listPath = _next(args, ++i, '--list');
          break;
        case '--config':
          configPath = _next(args, ++i, '--config') ?? configPath;
          break;
        case '--write':
          write = true;
          break;
        case '-h':
        case '--help':
          help = true;
          break;
        default:
          stderr.writeln('Unknown arg: $a');
          help = true;
      }
    }

    return _Cli(
      sequenceId: sequenceId,
      messageId: messageId,
      listPath: listPath,
      configPath: configPath,
      writeMode: write,
      showHelp: help,
    );
  }

  static String? _next(List<String> args, int i, String flag) {
    if (i >= args.length) {
      throw ArgumentError('Missing value after $flag');
    }
    return args[i];
  }
}

void _printHelp() {
  stdout.writeln('''
NOEXC Variant Generator

Usage:
  dart tool/gen_variants.dart --sequence <id> --message <id> [--config <file>] [--write]
  dart tool/gen_variants.dart --list targets.txt [--config <file>] [--write]

Options:
  --sequence <id>   Sequence ID (e.g., onboarding_seq)
  --message <id>    Message ID integer within the sequence
  --list <file>     File with lines: <sequenceId>:<messageId>
  --config <file>   Path to YAML config (default: tool/variants_config.yaml)
  --write           Actually append to content files (otherwise dry-run)
  --help, -h        Show this help
''');
}

// ---------------- Processing ----------------

class _Target {
  final String sequenceId;
  final int messageId;
  _Target(this.sequenceId, this.messageId);
}

class _ProcessOutcome {
  final String contentKey;
  final String targetFile;
  final List<String> acceptedVariants;
  final Map<String, dynamic> archiveRecord; // For writing to archive
  _ProcessOutcome(this.contentKey, this.targetFile, this.acceptedVariants, this.archiveRecord);
}

Future<_ProcessOutcome> _processTarget(
  _Target t,
  _Config config,
  bool writeMode,
) async {
  // 1) Load sequence + message
  final seqPath = 'assets/sequences/${t.sequenceId}.json';
  final seqJson = await _readJsonFile(seqPath);
  final List msgs = (seqJson['messages'] as List? ?? const []);
  Map<String, dynamic>? msg;
  for (final m in msgs) {
    if (m is Map && m['id'] is int && m['id'] == t.messageId) {
      msg = Map<String, dynamic>.from(m);
      break;
    }
  }
  if (msg == null) {
    throw Exception('Message ${t.messageId} not found in $seqPath');
  }

  final String? contentKey = (msg['contentKey'] as String?);
  if (contentKey == null || contentKey.isEmpty) {
    throw Exception('Message ${t.messageId} has no contentKey. Add one first.');
  }

  // 2) Resolve content path
  final key = _ContentKey.parse(contentKey);
  if (!key.isValid) {
    throw Exception('Invalid contentKey format: $contentKey');
  }
  final targetFile = key.toFilePath();

  // 3) Build context snapshot (previous K displayable messages)
  final context = _ContextBuilder(
    config: config,
    sequenceId: t.sequenceId,
    messagesJson: msgs.cast<Map<String, dynamic>>() ,
  ).buildSnapshotAround(t.messageId);

  // 4) Collect exemplars
  final exemplars = await _Exemplars.collect(key, config.context.maxExemplars);

  // 5) Load existing variants for this file (both exemplars and dedupe base)
  final existing = await _readLinesIfExists(targetFile);

  // 6) Build prompt
  final prompt = _PromptBuilder(
    contentKey: contentKey,
    targetPath: targetFile,
    contextSnapshot: context,
    siblingExemplars: exemplars,
    existingVariants: existing,
    config: config,
  ).build();

  // 7) Generate via LLM client (or mock)
  final generator = _Generator(config);
  final genResult = await generator.generate(prompt);

  // 8) Validate & dedupe
  final validator = _Validator(config);
  final validated = validator.validateBatch(genResult.variants, existing);

  // 9) Append (if write mode)
  if (writeMode) {
    await _appendLines(targetFile, validated);
  } else {
    stdout.writeln('   (dry-run) Would append to: $targetFile');
    for (final v in validated) {
      stdout.writeln('   + $v');
    }
  }

  // 10) Archive record
  final archiveRecord = _ArchiveRecord.create(
    config: config,
    target: t,
    contentKey: contentKey,
    targetFile: targetFile,
    contextSnapshot: context,
    exemplars: exemplars,
    existing: existing,
    prompt: prompt,
    llmResult: genResult.raw,
    accepted: validated,
  );
  await _ArchiveRecord.write(config.io.archiveDir, archiveRecord);

  return _ProcessOutcome(contentKey, targetFile, validated, archiveRecord);
}

Future<List<_Target>> _loadTargetsFromList(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw Exception('Targets file not found: $path');
  }
  final lines = await file.readAsLines();
  final targets = <_Target>[];
  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    final parts = line.split(':');
    if (parts.length != 2) {
      throw Exception('Invalid target line (expected seq:msg): $line');
    }
    final msgId = int.tryParse(parts[1]);
    if (msgId == null) {
      throw Exception('Invalid message id in line: $line');
    }
    targets.add(_Target(parts[0], msgId));
  }
  return targets;
}

// ---------------- Config ----------------

class _Config {
  final _ProviderConfig provider;
  final _GenConfig gen;
  final _ContextConfig context;
  final _StyleConfig style;
  final _IoConfig io;
  final _RateLimitConfig rateLimit;
  final _SafetyConfig safety;

  _Config(
    this.provider,
    this.gen,
    this.context,
    this.style,
    this.io,
    this.rateLimit,
    this.safety,
  );

  static Future<_Config> load(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      stdout.writeln('Config not found at $path. Using defaults and creating a sample.');
      await _writeDefaultConfigYaml(path);
    }
    final data = await _readConfigFlexible(file);
    return _Config(
      _ProviderConfig.fromJson(data['provider'] as Map<String, dynamic>? ?? const {}),
      _GenConfig.fromJson(data['gen'] as Map<String, dynamic>? ?? const {}),
      _ContextConfig.fromJson(data['context'] as Map<String, dynamic>? ?? const {}),
      _StyleConfig.fromJson(data['style'] as Map<String, dynamic>? ?? const {}),
      _IoConfig.fromJson(data['io'] as Map<String, dynamic>? ?? const {}),
      _RateLimitConfig.fromJson(data['rate_limit'] as Map<String, dynamic>? ?? const {}),
      _SafetyConfig.fromJson(data['safety'] as Map<String, dynamic>? ?? const {}),
    );
  }
  static Future<void> _writeDefaultConfigYaml(String path) async {
    final file = File(path);
    await file.create(recursive: true);
    const yaml = '''
provider:
  name: generic-json
  base_url: https://api.example.com/generate
  model: my-model
  api_key_env: LLM_API_KEY
  mock: true
  timeout_ms: 30000

gen:
  num_variants: 8
  temperature: 0.7
  top_p: 0.9
  max_bubbles_per_line: 3
  max_chars_per_bubble: 90
  dedupe_threshold: 0.82

context:
  history_bubbles: 4
  include_sibling_exemplars: true
  max_exemplars: 10

style:
  tone:
    - friendly
    - concise
    - supportive
  forbid_emojis: true
  allow_pipes: true
  preserve_placeholders: true

io:
  archive_dir: tool/ai_archive
  dry_run: true
  verbose: false
  fail_fast: false

rate_limit:
  rpm: 30
  retry_count: 2
  retry_backoff_ms: 1000

safety:
  blocklist:
    - shit
    - fuck
  pii_regexes: []
''';
    await file.writeAsString(yaml);
  }
}

class _ProviderConfig {
  final String name;
  final String baseUrl;
  final String model;
  final String apiKeyEnv;
  final bool mock;
  final int timeoutMs;
  _ProviderConfig({
    required this.name,
    required this.baseUrl,
    required this.model,
    required this.apiKeyEnv,
    required this.mock,
    required this.timeoutMs,
  });
  factory _ProviderConfig.fromJson(Map<String, dynamic> j) => _ProviderConfig(
    name: (j['name'] as String?) ?? 'generic-json',
    baseUrl: (j['base_url'] as String?) ?? '',
    model: (j['model'] as String?) ?? '',
    apiKeyEnv: (j['api_key_env'] as String?) ?? 'LLM_API_KEY',
    mock: (j['mock'] as bool?) ?? false,
    timeoutMs: (j['timeout_ms'] as int?) ?? 30000,
  );
}

class _GenConfig {
  final int numVariants;
  final double temperature;
  final double topP;
  final int maxBubblesPerLine;
  final int maxCharsPerBubble;
  final double dedupeThreshold;
  _GenConfig({
    required this.numVariants,
    required this.temperature,
    required this.topP,
    required this.maxBubblesPerLine,
    required this.maxCharsPerBubble,
    required this.dedupeThreshold,
  });
  factory _GenConfig.fromJson(Map<String, dynamic> j) => _GenConfig(
    numVariants: (j['num_variants'] as int?) ?? 8,
    temperature: ((j['temperature'] as num?) ?? 0.7).toDouble(),
    topP: ((j['top_p'] as num?) ?? 0.9).toDouble(),
    maxBubblesPerLine: (j['max_bubbles_per_line'] as int?) ?? 3,
    maxCharsPerBubble: (j['max_chars_per_bubble'] as int?) ?? 90,
    dedupeThreshold: ((j['dedupe_threshold'] as num?) ?? 0.82).toDouble(),
  );
}

class _ContextConfig {
  final int historyBubbles;
  final bool includeSiblingExemplars;
  final int maxExemplars;
  _ContextConfig({
    required this.historyBubbles,
    required this.includeSiblingExemplars,
    required this.maxExemplars,
  });
  factory _ContextConfig.fromJson(Map<String, dynamic> j) => _ContextConfig(
    historyBubbles: (j['history_bubbles'] as int?) ?? 4,
    includeSiblingExemplars: (j['include_sibling_exemplars'] as bool?) ?? true,
    maxExemplars: (j['max_exemplars'] as int?) ?? 10,
  );
}

class _StyleConfig {
  final List<String> tone;
  final bool forbidEmojis;
  final bool allowPipes;
  final bool preservePlaceholders;
  _StyleConfig({
    required this.tone,
    required this.forbidEmojis,
    required this.allowPipes,
    required this.preservePlaceholders,
  });
  factory _StyleConfig.fromJson(Map<String, dynamic> j) => _StyleConfig(
    tone: (j['tone'] as List?)?.cast<String>() ?? const ['friendly', 'concise'],
    forbidEmojis: (j['forbid_emojis'] as bool?) ?? true,
    allowPipes: (j['allow_pipes'] as bool?) ?? true,
    preservePlaceholders: (j['preserve_placeholders'] as bool?) ?? true,
  );
}

class _IoConfig {
  final String archiveDir;
  final bool dryRun;
  final bool verbose;
  final bool failFast;
  _IoConfig({
    required this.archiveDir,
    required this.dryRun,
    required this.verbose,
    required this.failFast,
  });
  factory _IoConfig.fromJson(Map<String, dynamic> j) => _IoConfig(
    archiveDir: (j['archive_dir'] as String?) ?? 'tool/ai_archive',
    dryRun: (j['dry_run'] as bool?) ?? true,
    verbose: (j['verbose'] as bool?) ?? false,
    failFast: (j['fail_fast'] as bool?) ?? false,
  );
}

class _RateLimitConfig {
  final int rpm;
  final int retryCount;
  final int retryBackoffMs;
  _RateLimitConfig({
    required this.rpm,
    required this.retryCount,
    required this.retryBackoffMs,
  });
  factory _RateLimitConfig.fromJson(Map<String, dynamic> j) => _RateLimitConfig(
    rpm: (j['rpm'] as int?) ?? 30,
    retryCount: (j['retry_count'] as int?) ?? 2,
    retryBackoffMs: (j['retry_backoff_ms'] as int?) ?? 1000,
  );
}

class _SafetyConfig {
  final List<String> blocklist;
  final List<String> piiRegexes; // Unused in scaffold; placeholder
  _SafetyConfig({required this.blocklist, required this.piiRegexes});
  factory _SafetyConfig.fromJson(Map<String, dynamic> j) => _SafetyConfig(
    blocklist: (j['blocklist'] as List?)?.cast<String>() ?? const [],
    piiRegexes: (j['pii_regexes'] as List?)?.cast<String>() ?? const [],
  );
}

// ---------------- ContentKey ----------------

class _ContentKey {
  final String actor;
  final String action;
  final String subject;
  final List<String> modifiers;
  final bool isValid;
  _ContentKey(this.actor, this.action, this.subject, this.modifiers, this.isValid);

  static _ContentKey parse(String key) {
    final parts = key.split('.');
    if (parts.length < 3) return _ContentKey('', '', '', const [], false);
    final actor = parts[0];
    final action = parts[1];
    final subject = parts[2];
    final modifiers = parts.length > 3 ? parts.sublist(3) : <String>[];
    return _ContentKey(actor, action, subject, modifiers, true);
  }

  String toFilePath() {
    final base = 'assets/content/$actor/$action/';
    final name = modifiers.isEmpty
        ? '${subject}.txt'
        : '${subject}_${modifiers.join('_')}.txt';
    return '$base$name';
  }

  String siblingsDir() => 'assets/content/$actor/$action';
}

// ---------------- Context Builder ----------------

class _ContextMessageView {
  final int id;
  final String type;
  final String sender;
  final String textOrKey; // Prefer resolved text if available; else contentKey or text
  _ContextMessageView({required this.id, required this.type, required this.sender, required this.textOrKey});
}

class _ContextBuilder {
  final _Config config;
  final String sequenceId;
  final List<Map<String, dynamic>> messagesJson;
  _ContextBuilder({required this.config, required this.sequenceId, required this.messagesJson});

  List<_ContextMessageView> buildSnapshotAround(int targetId) {
    // Take previous K displayable messages in the same sequence by order
    final idx = messagesJson.indexWhere((m) => (m['id'] as int?) == targetId);
    if (idx <= 0) return [];
    final List<_ContextMessageView> out = [];
    for (int i = idx - 1; i >= 0 && out.length < config.context.historyBubbles; i--) {
      final m = messagesJson[i];
      final type = (m['type'] as String?) ?? 'bot';
      if (_isDisplayable(type)) {
        final sender = (m['sender'] as String?) ?? (type == 'user' ? 'user' : 'bot');
        final contentKey = m['contentKey'] as String?;
        final text = (m['text'] as String?) ?? '';
        final view = _ContextMessageView(
          id: m['id'] as int,
          type: type,
          sender: sender,
          textOrKey: (contentKey != null && contentKey.isNotEmpty) ? 'contentKey:$contentKey' : text,
        );
        out.add(view);
      }
    }
    return out.reversed.toList(growable: false);
  }

  bool _isDisplayable(String type) {
    return type != 'autoroute' && type != 'dataAction';
  }
}

// ---------------- Exemplars ----------------

class _Exemplars {
  static Future<List<String>> collect(_ContentKey key, int maxExemplars) async {
    final dir = Directory(key.siblingsDir());
    if (!await dir.exists()) return const [];
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.txt'))
        .cast<File>()
        .toList();
    final List<String> lines = [];
    for (final f in files) {
      final ls = await f.readAsLines();
      for (final l in ls) {
        final s = l.trim();
        if (s.isNotEmpty) lines.add(s);
        if (lines.length >= maxExemplars) return lines;
      }
    }
    return lines;
  }
}

// ---------------- Prompt Builder ----------------

class _PromptBuilder {
  final String contentKey;
  final String targetPath;
  final List<_ContextMessageView> contextSnapshot;
  final List<String> siblingExemplars;
  final List<String> existingVariants;
  final _Config config;
  _PromptBuilder({
    required this.contentKey,
    required this.targetPath,
    required this.contextSnapshot,
    required this.siblingExemplars,
    required this.existingVariants,
    required this.config,
  });

  Map<String, dynamic> build() {
    final system = 'You are a UX writer for NOEXC, a friendly accountability bot. '
        'Write multiple alternative lines for the specified contentKey. '
        'Keep placeholders like {user.name} exactly unchanged. '
        'Use ||| to split long messages into multiple bubbles (max ${config.gen.maxBubblesPerLine}). '
        '${config.style.forbidEmojis ? 'Do not use emojis.' : ''} '
        'Tone: ${config.style.tone.join(', ')}. Concise, natural, no marketing fluff.';

    final context = contextSnapshot
        .map((m) => {
              'sender': m.sender,
              'type': m.type,
              'text': m.textOrKey,
            })
        .toList();

    return {
      'system': system,
      'task': {
        'contentKey': contentKey,
        'targetPath': targetPath,
        'constraints': {
          'numVariants': config.gen.numVariants,
          'maxBubblesPerLine': config.gen.maxBubblesPerLine,
          'maxCharsPerBubble': config.gen.maxCharsPerBubble,
          'preservePlaceholders': config.style.preservePlaceholders,
        },
      },
      'context': context,
      'exemplars': {
        'existingVariants': existingVariants,
        'siblingExemplars': siblingExemplars.take(config.context.maxExemplars).toList(),
      },
      'output_format': {
        'type': 'json',
        'schema': {'variants': ['string']}
      }
    };
  }
}

// ---------------- Generator (LLM REST) ----------------

class _GenResult {
  final List<String> variants;
  final Map<String, dynamic> raw;
  _GenResult(this.variants, this.raw);
}

class _Generator {
  final _Config config;
  _Generator(this.config);

  Future<_GenResult> generate(Map<String, dynamic> prompt) async {
    if (config.provider.mock || config.io.dryRun) {
      // Produce mock variants for scaffolding & dry-runs
      final n = config.gen.numVariants;
      final ck = (prompt['task'] as Map)['contentKey'];
      final now = DateTime.now().millisecondsSinceEpoch;
      final variants = List<String>.generate(
        n,
        (i) => '[$ck] Variant ${i + 1} at $now ||| Second bubble (optional)',
      );
      return _GenResult(variants, {
        'mock': true,
        'prompt': prompt,
        'model': config.provider.model,
      });
    }

    final apiKey = Platform.environment[config.provider.apiKeyEnv] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('Missing API key env: ${config.provider.apiKeyEnv}');
    }

    final uri = Uri.parse(config.provider.baseUrl);
    final client = HttpClient();
    client.connectionTimeout = Duration(milliseconds: config.provider.timeoutMs);

    // Generic JSON contract: { model, temperature, top_p, prompt: <object> }
    final payload = jsonEncode({
      'model': config.provider.model,
      'temperature': config.gen.temperature,
      'top_p': config.gen.topP,
      'n': config.gen.numVariants,
      'prompt': prompt,
    });

    for (int attempt = 0;; attempt++) {
      try {
        final req = await client.postUrl(uri);
        req.headers.set('content-type', 'application/json');
        req.headers.set('authorization', 'Bearer $apiKey');
        req.write(payload);
        final res = await req.close();
        final body = await utf8.decodeStream(res);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final obj = jsonDecode(body) as Map<String, dynamic>;
          final variants = _extractVariants(obj);
          return _GenResult(variants, obj);
        } else {
          throw HttpException('HTTP ${res.statusCode}: $body');
        }
      } catch (e) {
        if (attempt >= config.rateLimit.retryCount) rethrow;
        await Future.delayed(Duration(milliseconds: config.rateLimit.retryBackoffMs));
      }
    }
  }

  List<String> _extractVariants(Map<String, dynamic> obj) {
    // Expect { variants: [ ... ] } but allow nested mapping via common fields
    if (obj['variants'] is List) {
      return (obj['variants'] as List).map((e) => e.toString()).toList();
    }
    // Fallbacks: some providers return { choices: [ { text: ... } ] }
    if (obj['choices'] is List) {
      final choices = obj['choices'] as List;
      return choices
          .map((c) => (c is Map && c['text'] != null) ? c['text'].toString() : null)
          .whereType<String>()
          .toList();
    }
    throw Exception('Cannot extract variants from response');
  }
}

// ---------------- Validator & Dedupe ----------------

class _Validator {
  final _Config config;
  _Validator(this.config);

  List<String> validateBatch(List<String> raw, List<String> existingBase) {
    final out = <String>[];
    final seen = <String>[]; // For intra-batch dedupe
    for (final r in raw) {
      var s = r.trim();
      if (s.isEmpty) continue;
      s = s.replaceAll('\t', ' ');
      if (!_placeholdersOk(s)) continue;
      final parts = s.split('|||');
      if (parts.length > config.gen.maxBubblesPerLine) continue;
      bool overLimit = false;
      for (final p in parts) {
        if (p.trim().length > config.gen.maxCharsPerBubble) {
          overLimit = true;
          break;
        }
      }
      if (overLimit) continue;
      if (_containsBlocked(s)) continue;
      if (_isNearDuplicate(s, existingBase)) continue;
      if (_isNearDuplicate(s, seen)) continue;
      out.add(s);
      seen.add(s);
    }
    return out;
  }

  bool _placeholdersOk(String s) {
    // Simple brace balance check; ensure we don't break { ... }
    int open = 0;
    for (final r in s.runes) {
      if (r == 123) open++; // '{'
      if (r == 125) open--; // '}'
      if (open < 0) return false;
    }
    return open == 0;
  }

  bool _containsBlocked(String s) {
    final lowered = s.toLowerCase();
    for (final w in config.safety.blocklist) {
      if (lowered.contains(w.toLowerCase())) return true;
    }
    return false;
  }

  bool _isNearDuplicate(String s, List<String> pool) {
    for (final p in pool) {
      if (_similarity(s, p) >= config.gen.dedupeThreshold) return true;
    }
    return false;
  }

  double _similarity(String a, String b) {
    final ta = _tokenSet(a);
    final tb = _tokenSet(b);
    final inter = ta.intersection(tb).length.toDouble();
    final union = (ta.length + tb.length - inter).toDouble();
    if (union <= 0) return 0;
    return inter / union;
  }

  Set<String> _tokenSet(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s\|]'), ' ')
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toSet();
  }
}

// ---------------- Archive ----------------

class _ArchiveRecord {
  static Map<String, dynamic> create({
    required _Config config,
    required _Target target,
    required String contentKey,
    required String targetFile,
    required List<_ContextMessageView> contextSnapshot,
    required List<String> exemplars,
    required List<String> existing,
    required Map<String, dynamic> prompt,
    required Map<String, dynamic> llmResult,
    required List<String> accepted,
  }) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'target': {
        'sequenceId': target.sequenceId,
        'messageId': target.messageId,
        'contentKey': contentKey,
        'targetFile': targetFile,
      },
      'config': _jsonConfig(config),
      'context': contextSnapshot
          .map((m) => {'id': m.id, 'sender': m.sender, 'type': m.type, 'text': m.textOrKey})
          .toList(),
      'exemplars': {
        'siblingSample': exemplars,
        'existingVariants': existing,
      },
      'prompt': prompt,
      'response': llmResult,
      'acceptedVariants': accepted,
    };
  }

  static Future<void> write(String baseDir, Map<String, dynamic> record) async {
    final target = record['target'] as Map<String, dynamic>;
    final key = (target['contentKey'] as String?) ?? 'unknown.key';
    final idHash = _hashString('${target['sequenceId']}:${target['messageId']}:$key');
    final now = DateTime.now();
    final dir = Directory(
        '$baseDir/${now.year.toString().padLeft(4, '0')}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}');
    await dir.create(recursive: true);
    final file = File('${dir.path}/${now.millisecondsSinceEpoch}_$idHash.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(record));
  }

  static String _hashString(String s) {
    // djb2 hash (simple, non-crypto)
    int hash = 5381;
    for (final code in s.codeUnits) {
      hash = ((hash << 5) + hash) + code;
    }
    return hash.abs().toString();
  }

  static Map<String, dynamic> _jsonConfig(_Config c) => {
        'provider': {
          'name': c.provider.name,
          'base_url': c.provider.baseUrl,
          'model': c.provider.model,
          'api_key_env': c.provider.apiKeyEnv,
          'mock': c.provider.mock,
          'timeout_ms': c.provider.timeoutMs,
        },
        'gen': {
          'num_variants': c.gen.numVariants,
          'temperature': c.gen.temperature,
          'top_p': c.gen.topP,
          'max_bubbles_per_line': c.gen.maxBubblesPerLine,
          'max_chars_per_bubble': c.gen.maxCharsPerBubble,
          'dedupe_threshold': c.gen.dedupeThreshold,
        },
        'context': {
          'history_bubbles': c.context.historyBubbles,
          'include_sibling_exemplars': c.context.includeSiblingExemplars,
          'max_exemplars': c.context.maxExemplars,
        },
        'style': {
          'tone': c.style.tone,
          'forbid_emojis': c.style.forbidEmojis,
          'allow_pipes': c.style.allowPipes,
          'preserve_placeholders': c.style.preservePlaceholders,
        },
        'io': {
          'archive_dir': c.io.archiveDir,
          'dry_run': c.io.dryRun,
          'verbose': c.io.verbose,
          'fail_fast': c.io.failFast,
        },
        'rate_limit': {
          'rpm': c.rateLimit.rpm,
          'retry_count': c.rateLimit.retryCount,
          'retry_backoff_ms': c.rateLimit.retryBackoffMs,
        },
        'safety': {
          'blocklist': c.safety.blocklist,
          'pii_regexes': c.safety.piiRegexes,
        },
      };
}

// Attempt to read config as JSON first, then YAML (minimal parser)
Future<Map<String, dynamic>> _readConfigFlexible(File file) async {
  final content = await file.readAsString();
  // Try JSON
  try {
    final data = jsonDecode(content);
    if (data is Map<String, dynamic>) return data;
  } catch (_) {}
  // Parse YAML (subset)
  return _MiniYaml.parse(content);
}

// ---------------- Minimal YAML parser (subset sufficient for our config) ----------------

class _MiniYaml {
  // Minimal YAML parser for our config
  // Supports maps, lists, and scalars. No anchors/aliases.
  static Map<String, dynamic> parse(String yaml) {
    final lines = yaml.replaceAll('\r\n', '\n').split('\n');
    int idx = 0;
    final root = <String, dynamic>{};
    final stack = <_Node>[_Node(indent: -1, container: root, isList: false)];

    String? nextSigLine(int from) {
      for (int i = from; i < lines.length; i++) {
        var l = lines[i];
        final hash = l.indexOf('#');
        if (hash >= 0) l = l.substring(0, hash);
        if (l.trim().isEmpty) continue;
        return l.trimLeft();
      }
      return null;
    }

    while (idx < lines.length) {
      var line = lines[idx++];
      // Strip comments
      final hash = line.indexOf('#');
      if (hash >= 0) line = line.substring(0, hash);
      if (line.trim().isEmpty) continue;

      final indent = _countLeadingSpaces(line);
      final trimmedLeft = line.trimLeft();

      // Adjust stack for current indent
      while (stack.isNotEmpty && indent <= stack.last.indent) {
        stack.removeLast();
      }
      if (stack.isEmpty) throw FormatException('YAML indentation error');

      final top = stack.last;

      if (trimmedLeft.startsWith('- ')) {
        if (!top.isList) throw FormatException('List item in non-list context');
        final itemStr = trimmedLeft.substring(2).trim();
        if (itemStr.isEmpty) {
          // Nested structure item (we only need maps for our config)
          final map = <String, dynamic>{};
          (top.container as List).add(map);
          stack.add(_Node(indent: indent, container: map, isList: false));
        } else {
          (top.container as List).add(_parseScalar(itemStr));
        }
        continue;
      }

      final colon = trimmedLeft.indexOf(':');
      if (colon < 0) throw FormatException('Expected key: value — got "$trimmedLeft"');
      final key = trimmedLeft.substring(0, colon).trim();
      final rest = trimmedLeft.substring(colon + 1).trim();

      if (top.isList) throw FormatException('Key in list context');
      final map = top.container as Map<String, dynamic>;

      if (rest.isEmpty) {
        // Decide whether nested block is a list or a map via lookahead
        final peek = nextSigLine(idx);
        if (peek != null && peek.startsWith('- ')) {
          final list = <dynamic>[];
          map[key] = list;
          stack.add(_Node(indent: indent, container: list, isList: true));
        } else {
          final child = <String, dynamic>{};
          map[key] = child;
          stack.add(_Node(indent: indent, container: child, isList: false));
        }
      } else {
        map[key] = _parseScalar(rest);
      }
    }

    return root;
  }

  static int _countLeadingSpaces(String s) {
    int c = 0;
    while (c < s.length && s.codeUnitAt(c) == 32) c++;
    return c;
  }

  static dynamic _parseScalar(String s) {
    // Flow-style list: [] or [a, b, c]
    if (s.startsWith('[') && s.endsWith(']')) {
      final inner = s.substring(1, s.length - 1).trim();
      if (inner.isEmpty) return <dynamic>[];
      final parts = inner.split(',');
      return parts
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((e) {
            // remove optional quotes around each item
            if ((e.startsWith('"') && e.endsWith('"')) ||
                (e.startsWith("'") && e.endsWith("'"))) {
              return e.substring(1, e.length - 1);
            }
            // try simple scalars
            final i = int.tryParse(e);
            if (i != null) return i;
            final d = double.tryParse(e);
            if (d != null) return d;
            if (e == 'true') return true;
            if (e == 'false') return false;
            return e;
          })
          .toList();
    }
    if (s == 'true') return true;
    if (s == 'false') return false;
    final i = int.tryParse(s);
    if (i != null) return i;
    final d = double.tryParse(s);
    if (d != null) return d;
    if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
      return s.substring(1, s.length - 1);
    }
    return s;
  }
}

class _Node {
  final int indent;
  final dynamic container; // Map or List
  final bool isList;
  _Node({required this.indent, required this.container, required this.isList});
}

// ---------------- File Utilities ----------------

Future<Map<String, dynamic>> _readJsonFile(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw Exception('File not found: $path');
  }
  try {
    return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  } catch (e) {
    throw Exception('Invalid JSON in $path: $e');
  }
}

Future<List<String>> _readLinesIfExists(String path) async {
  final file = File(path);
  if (!await file.exists()) return const [];
  try {
    return (await file.readAsLines()).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  } catch (_) {
    return const [];
  }
}

Future<void> _appendLines(String path, List<String> lines) async {
  if (lines.isEmpty) return;
  final file = File(path);
  await file.create(recursive: true);
  final sink = file.openWrite(mode: FileMode.append);
  try {
    for (final l in lines) {
      sink.writeln(l.trim());
    }
  } finally {
    await sink.close();
  }
}
