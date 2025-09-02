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
      final result = await _processTarget(t, config, cli.writeMode, cli.statePath);
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
  final String? statePath;
  final bool showHelp;

  _Cli({
    this.sequenceId,
    this.messageId,
    this.listPath,
    required this.configPath,
    required this.writeMode,
    this.statePath,
    required this.showHelp,
  });

  static _Cli parse(List<String> args) {
    String? sequenceId;
    int? messageId;
    String? listPath;
    String configPath = 'tool/variants_config.yaml';
    bool write = false;
    String? statePath;
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
        case '--state':
          statePath = _next(args, ++i, '--state');
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
      statePath: statePath,
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
  --state <file>    Optional YAML state file to resolve a concrete path for context
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
  String? statePath,
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

  // 3) Build context snapshot
  List<_ContextMessageView> context;
  _ResolvedPath? resolvedPath;
  String? stateFileUsed;
  if (statePath != null) {
    // Load state and resolve a concrete path
    final stateSpec = await _StateSpec.load(statePath);
    stateFileUsed = statePath;
    final index = _SequenceIndex();
    final resolver = _PathResolver(index: index, config: config);
    resolvedPath = await resolver.resolve(
      state: stateSpec,
      targetSeq: t.sequenceId,
      targetId: t.messageId,
    );
    context = _ResolvedContextBuilder(
      config: config,
      index: index,
      resolvedPath: resolvedPath,
    ).buildWindow();
  } else {
    // Fallback: previous K displayable in same sequence
    context = _ContextBuilder(
      config: config,
      sequenceId: t.sequenceId,
      messagesJson: msgs.cast<Map<String, dynamic>>(),
    ).buildSnapshotAround(t.messageId);
  }

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

  // Attach target's default text and existing variants to the task in prompt
  final targetDefaultText = (msg['text'] as String?) ?? '';
  if (targetDefaultText.isNotEmpty) {
    (prompt['task'] as Map<String, dynamic>)['defaultText'] = targetDefaultText;
  }
  if (existing.isNotEmpty) {
    (prompt['task'] as Map<String, dynamic>)['existingVariants'] = existing;
  }

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
    request: genResult.request,
    llmResult: genResult.raw,
    accepted: validated,
    stateFile: stateFileUsed,
    resolvedPath: resolvedPath,
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
  final _PromptTextConfig promptCfg;

  _Config(
    this.provider,
    this.gen,
    this.context,
    this.style,
    this.io,
    this.rateLimit,
    this.safety,
    this.promptCfg,
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
      _PromptTextConfig.fromJson(data['prompt'] as Map<String, dynamic>? ?? const {}),
    );
  }
  static Future<void> _writeDefaultConfigYaml(String path) async {
    final file = File(path);
    await file.create(recursive: true);
    const yaml = '''
provider:
  # Use 'openai-chat' for Chat Completions API
  name: openai-chat
  # Leave base_url empty to use default https://api.openai.com/v1/chat/completions
  base_url: ""
  model: gpt-4o-mini
  api_key_env: OPENAI_API_KEY
  mock: true
  timeout_ms: 30000

gen:
  num_variants: 8
  temperature: 0.7
  top_p: 0.9
  max_bubbles_per_line: 3
  max_chars_per_bubble: 90
  dedupe_threshold: 0.82
  max_tokens: 512

context:
  history_bubbles: 4
  include_sibling_exemplars: false
  max_exemplars: 10
  include_node_samples: true
  samples_per_node: 3
  prefer_node_samples: true

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

prompt:
  system_message: "You are a UX writer for NOEXC, a friendly accountability bot."
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
  final int maxTokens;
  final bool includeSamplingParams; // temperature/top_p
  _GenConfig({
    required this.numVariants,
    required this.temperature,
    required this.topP,
    required this.maxBubblesPerLine,
    required this.maxCharsPerBubble,
    required this.dedupeThreshold,
    required this.maxTokens,
    required this.includeSamplingParams,
  });
  factory _GenConfig.fromJson(Map<String, dynamic> j) => _GenConfig(
    numVariants: (j['num_variants'] as int?) ?? 8,
    temperature: ((j['temperature'] as num?) ?? 0.7).toDouble(),
    topP: ((j['top_p'] as num?) ?? 0.9).toDouble(),
    maxBubblesPerLine: (j['max_bubbles_per_line'] as int?) ?? 3,
    maxCharsPerBubble: (j['max_chars_per_bubble'] as int?) ?? 90,
    dedupeThreshold: ((j['dedupe_threshold'] as num?) ?? 0.82).toDouble(),
    maxTokens: (j['max_tokens'] as int?) ?? 512,
    includeSamplingParams: (j['include_sampling_params'] as bool?) ?? true,
  );
}

class _ContextConfig {
  final int historyBubbles;
  final bool includeSiblingExemplars;
  final int maxExemplars;
  final bool includeNodeSamples;
  final int samplesPerNode;
  final bool preferNodeSamples;
  _ContextConfig({
    required this.historyBubbles,
    required this.includeSiblingExemplars,
    required this.maxExemplars,
    required this.includeNodeSamples,
    required this.samplesPerNode,
    required this.preferNodeSamples,
  });
  factory _ContextConfig.fromJson(Map<String, dynamic> j) => _ContextConfig(
    historyBubbles: (j['history_bubbles'] as int?) ?? 4,
    includeSiblingExemplars: (j['include_sibling_exemplars'] as bool?) ?? false,
    maxExemplars: (j['max_exemplars'] as int?) ?? 10,
    includeNodeSamples: (j['include_node_samples'] as bool?) ?? true,
    samplesPerNode: (j['samples_per_node'] as int?) ?? 3,
    preferNodeSamples: (j['prefer_node_samples'] as bool?) ?? true,
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

class _PromptTextConfig {
  final String systemMessage;
  _PromptTextConfig({required this.systemMessage});
  factory _PromptTextConfig.fromJson(Map<String, dynamic> j) => _PromptTextConfig(
        systemMessage: (j['system_message'] as String?) ??
            'You are a UX writer for NOEXC, a friendly accountability bot.',
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
  final String? defaultText; // Script default text for messages or selected choice text
  _ContextMessageView({required this.id, required this.type, required this.sender, required this.textOrKey, this.defaultText});
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
          defaultText: (type == 'choice') ? null : (m['text'] as String? ?? ''),
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

// ---------------- State-aware Path & Context ----------------

class _StateSpec {
  final String? startSequence;
  final int? startMessage;
  final String autoroutesMode; // 'resolve' or 'default'
  final Map<String, dynamic> values;
  final List<_ChoiceDirective> choices;
  final int maxDepth;
  final int maxPaths;

  _StateSpec({
    this.startSequence,
    this.startMessage,
    required this.autoroutesMode,
    required this.values,
    required this.choices,
    required this.maxDepth,
    required this.maxPaths,
  });

  static Future<_StateSpec> load(String path) async {
    final file = File(path);
    if (!await file.exists()) throw Exception('State file not found: $path');
    final raw = await file.readAsString();
    final data = _MiniYaml.parse(raw);
    final entry = (data['entry'] as Map?)?.cast<String, dynamic>() ?? {};
    final routing = (data['routing'] as Map?)?.cast<String, dynamic>() ?? {};
    final values = (data['values'] as Map?)?.cast<String, dynamic>() ?? {};
    final choicesRaw = (data['choices'] as List?) ?? const [];
    final limits = (data['limits'] as Map?)?.cast<String, dynamic>() ?? {};

    final choices = <_ChoiceDirective>[];
    for (final c in choicesRaw) {
      if (c is Map) {
        final at = (c['at'] as Map?)?.cast<String, dynamic>() ?? {};
        final by = (c['by'] as String?) ?? 'index';
        final sel = c['select'];
        final seq = at['sequenceId']?.toString();
        final mid = at['messageId'] is int ? at['messageId'] as int : int.tryParse(at['messageId']?.toString() ?? '');
        if (seq != null && mid != null) {
          choices.add(_ChoiceDirective(sequenceId: seq, messageId: mid, by: by, select: sel));
        }
      }
    }

    return _StateSpec(
      startSequence: entry['start_sequence']?.toString(),
      startMessage: entry['start_message'] is int ? entry['start_message'] as int : int.tryParse(entry['start_message']?.toString() ?? ''),
      autoroutesMode: (routing['autoroutes']?.toString() ?? 'resolve').toLowerCase(),
      values: values,
      choices: choices,
      maxDepth: (limits['max_depth'] is int) ? limits['max_depth'] as int : (int.tryParse(limits['max_depth']?.toString() ?? '') ?? 60),
      maxPaths: (limits['max_paths'] is int) ? limits['max_paths'] as int : (int.tryParse(limits['max_paths']?.toString() ?? '') ?? 20),
    );
  }
}

class _ChoiceDirective {
  final String sequenceId;
  final int messageId;
  final String by; // 'index' | 'text' | 'contentKey'
  final dynamic select; // int or string
  _ChoiceDirective({required this.sequenceId, required this.messageId, required this.by, required this.select});
}

class _SequenceIndex {
  final Map<String, Map<int, Map<String, dynamic>>> _seqCache = {};
  final Map<String, int?> _firstIdCache = {};

  Future<Map<String, dynamic>?> getMessage(String seq, int id) async {
    await _ensureLoaded(seq);
    return _seqCache[seq]?[id];
  }

  Future<bool> hasMessage(String seq, int id) async {
    await _ensureLoaded(seq);
    return _seqCache[seq]?.containsKey(id) ?? false;
  }

  Future<int?> firstMessageId(String seq) async {
    await _ensureLoaded(seq);
    return _firstIdCache[seq];
  }

  Future<void> _ensureLoaded(String seq) async {
    if (_seqCache.containsKey(seq)) return;
    final data = await _readJsonFile('assets/sequences/$seq.json');
    final msgs = (data['messages'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final map = <int, Map<String, dynamic>>{};
    for (final m in msgs) {
      final id = m['id'];
      if (id is int) map[id] = m;
    }
    _seqCache[seq] = map;
    _firstIdCache[seq] = msgs.isNotEmpty && msgs.first['id'] is int ? msgs.first['id'] as int : null;
  }
}

class _ResolvedPathNode {
  final String sequenceId;
  final int messageId;
  final String? type;
  final Map<String, dynamic>? choiceSelected; // {index, text, contentKey}
  _ResolvedPathNode({required this.sequenceId, required this.messageId, this.type, this.choiceSelected});

  Map<String, dynamic> toJson() => {
        'sequenceId': sequenceId,
        'messageId': messageId,
        if (type != null) 'type': type,
        if (choiceSelected != null) 'choiceSelected': choiceSelected,
      };
}

class _ResolvedPath {
  final List<_ResolvedPathNode> nodes;
  _ResolvedPath(this.nodes);
  Map<String, dynamic> toJson() => {'nodes': nodes.map((n) => n.toJson()).toList()};
}

class _PathResolver {
  final _SequenceIndex index;
  final _Config config;
  _PathResolver({required this.index, required this.config});

  Future<_ResolvedPath> resolve({required _StateSpec state, required String targetSeq, required int targetId}) async {
    final startSeq = state.startSequence ?? targetSeq;
    final startId = state.startMessage ?? (await index.firstMessageId(startSeq)) ?? targetId;

    // BFS for shortest path
    final startMsg = await index.getMessage(startSeq, startId);
    if (startMsg == null) {
      return _ResolvedPath([_ResolvedPathNode(sequenceId: targetSeq, messageId: targetId, type: (await index.getMessage(targetSeq, targetId))?['type']?.toString())]);
    }

    final queue = <List<_ResolvedPathNode>>[];
    queue.add([_ResolvedPathNode(sequenceId: startSeq, messageId: startId, type: (startMsg['type'] as String?) ?? 'bot')]);
    final seen = <String>{};

    while (queue.isNotEmpty) {
      final path = queue.removeAt(0);
      final last = path.last;
      if (last.sequenceId == targetSeq && last.messageId == targetId) {
        return _ResolvedPath(path);
      }
      final key = '${last.sequenceId}:${last.messageId}';
      if (seen.contains(key) || path.length > state.maxDepth) continue;
      seen.add(key);

      final msg = await index.getMessage(last.sequenceId, last.messageId);
      if (msg == null) continue;
      final neighborsRaw = await _neighbors(state, last.sequenceId, last.messageId, msg);
      // Work on a modifiable copy to avoid sorting unmodifiable lists
      final neighbors = List<_ResolvedPathNode>.from(neighborsRaw);
      // Minor goal-directed ordering: push neighbor that is exactly the target first
      neighbors.sort((a, b) {
        final at = (a.sequenceId == targetSeq && a.messageId == targetId) ? 0 : 1;
        final bt = (b.sequenceId == targetSeq && b.messageId == targetId) ? 0 : 1;
        return at.compareTo(bt);
      });
      for (final n in neighbors) {
        final nextMsg = await index.getMessage(n.sequenceId, n.messageId);
        final typed = _ResolvedPathNode(
          sequenceId: n.sequenceId,
          messageId: n.messageId,
          type: nextMsg?['type']?.toString(),
          choiceSelected: n.choiceSelected,
        );
        final nextPath = List<_ResolvedPathNode>.from(path)..add(typed);
        queue.add(nextPath);
      }
    }

    // Fallback: just target
    return _ResolvedPath([_ResolvedPathNode(sequenceId: targetSeq, messageId: targetId, type: (await index.getMessage(targetSeq, targetId))?['type']?.toString())]);
  }

  Future<List<_ResolvedPathNode>> _neighbors(_StateSpec state, String seq, int id, Map<String, dynamic> msg) async {
    final type = (msg['type'] as String?) ?? 'bot';

    // Cross-sequence jump on message
    if (msg['sequenceId'] != null) {
      final toSeq = msg['sequenceId'].toString();
      final first = await index.firstMessageId(toSeq);
      if (first != null) return [_ResolvedPathNode(sequenceId: toSeq, messageId: first)];
    }

    if (type == 'autoroute') {
      final routes = (msg['routes'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      if (routes.isEmpty) {
        final next = await _fallbackNext(seq, id, msg);
        return next == null ? const [] : [next];
      }
      if (state.autoroutesMode == 'resolve') {
        // Try non-default with matching condition first
        for (final r in routes) {
          if (r['default'] == true) continue;
          final cond = r['condition']?.toString();
          if (cond != null && await _Condition(state.values).evaluateCompound(cond)) {
            return [await _routeToNode(r, currentSeq: seq)];
          }
        }
      }
      // Default route
      for (final r in routes) {
        if (r['default'] == true) {
          return [await _routeToNode(r, currentSeq: seq)];
        }
      }
      // Fallback: first route
      return [await _routeToNode(routes.first, currentSeq: seq)];
    }

    if (type == 'choice') {
      final choices = (msg['choices'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final directed = await _matchChoiceDirective(state, seq, id, choices);
      if (directed != null) return [directed];
      // Try all choices (DFS will pick first path reaching target)
      final out = <_ResolvedPathNode>[];
      for (int i = 0; i < choices.length; i++) {
        final ch = choices[i];
        final node = await _choiceToNode(ch, seq);
        if (node != null) {
          out.add(_ResolvedPathNode(
            sequenceId: node.sequenceId,
            messageId: node.messageId,
            choiceSelected: {
              'index': i,
              if (ch['text'] != null) 'text': ch['text'],
              if (ch['contentKey'] != null) 'contentKey': ch['contentKey'],
            },
          ));
        }
      }
      return out;
    }

    // dataAction, text, etc.
    final next = await _fallbackNext(seq, id, msg);
    return next == null ? const [] : [next];
  }

  Future<_ResolvedPathNode?> _matchChoiceDirective(_StateSpec state, String seq, int id, List<Map<String, dynamic>> choices) async {
    final dir = state.choices.firstWhere(
      (c) => c.sequenceId == seq && c.messageId == id,
      orElse: () => _ChoiceDirective(sequenceId: '', messageId: -1, by: '', select: null),
    );
    if (dir.messageId == -1) return null;
    int index = -1;
    if (dir.by == 'index' && dir.select is int) {
      index = dir.select as int;
    } else if (dir.by == 'text' && dir.select is String) {
      index = choices.indexWhere((c) => (c['text']?.toString() ?? '') == (dir.select as String));
    } else if (dir.by == 'contentKey' && dir.select is String) {
      index = choices.indexWhere((c) => (c['contentKey']?.toString() ?? '') == (dir.select as String));
    }
    if (index < 0 || index >= choices.length) return null;
    final ch = choices[index];
    final next = await _choiceToNode(ch, seq);
    if (next == null) return null;
    return _ResolvedPathNode(
      sequenceId: next.sequenceId,
      messageId: next.messageId,
      choiceSelected: {
        'index': index,
        if (ch['text'] != null) 'text': ch['text'],
        if (ch['contentKey'] != null) 'contentKey': ch['contentKey'],
      },
    );
  }

  Future<_ResolvedPathNode> _routeToNode(Map<String, dynamic> route, {required String currentSeq}) async {
    if (route['sequenceId'] != null) {
      final s = route['sequenceId'].toString();
      final first = await index.firstMessageId(s);
      if (first == null) throw Exception('Sequence $s has no messages');
      return _ResolvedPathNode(sequenceId: s, messageId: first);
    }
    final next = route['nextMessageId'] as int?;
    if (next == null) throw Exception('Route missing nextMessageId/sequenceId');
    return _ResolvedPathNode(sequenceId: currentSeq, messageId: next);
  }

  Future<_ResolvedPathNode?> _choiceToNode(Map<String, dynamic> ch, String currentSeq) async {
    if (ch['sequenceId'] != null) {
      final s = ch['sequenceId'].toString();
      final first = await index.firstMessageId(s);
      if (first == null) return null;
      return _ResolvedPathNode(sequenceId: s, messageId: first);
    }
    final next = ch['nextMessageId'] as int?;
    if (next != null) return _ResolvedPathNode(sequenceId: currentSeq, messageId: next);
    return null;
  }

  Future<_ResolvedPathNode?> _fallbackNext(String seq, int id, Map<String, dynamic> msg) async {
    if (msg['nextMessageId'] is int) {
      return _ResolvedPathNode(sequenceId: seq, messageId: msg['nextMessageId'] as int);
    }
    // implicit id+1 if exists
    if (await index.hasMessage(seq, id + 1)) {
      return _ResolvedPathNode(sequenceId: seq, messageId: id + 1);
    }
    return null;
  }
}

class _ResolvedContextBuilder {
  final _Config config;
  final _SequenceIndex index;
  final _ResolvedPath? resolvedPath;
  _ResolvedContextBuilder({required this.config, required this.index, required this.resolvedPath});

  List<_ContextMessageView> buildWindow() {
    if (resolvedPath == null) return const [];
    final nodes = resolvedPath!.nodes;
    if (nodes.isEmpty) return const [];
    // From all nodes except the final target, project displayable context turns
    final turns = <_ContextMessageView>[];
    for (int i = 0; i < nodes.length - 1; i++) {
      final n = nodes[i];
      final msg = index._seqCache[n.sequenceId]?[n.messageId];
      final type = n.type ?? (msg?['type']?.toString() ?? 'bot');
      if (type == 'choice') {
        // Represent the user selection; if not on this node, look ahead to next node's choiceSelected
        Map<String, dynamic>? sel = n.choiceSelected;
        if (sel == null && i + 1 < nodes.length) {
          sel = nodes[i + 1].choiceSelected;
        }
        final hasKey = sel != null && (sel['contentKey']?.toString().isNotEmpty ?? false);
        final ref = hasKey
            ? 'contentKey:${sel!['contentKey']}'
            : (sel != null ? (sel['text']?.toString() ?? 'user_choice') : 'user_choice');
        turns.add(_ContextMessageView(
          id: n.messageId,
          type: 'choice',
          sender: 'user',
          textOrKey: ref,
          defaultText: sel != null ? sel['text']?.toString() : null,
        ));
        continue;
      }
      if (type == 'autoroute' || type == 'dataAction') {
        // Skip non-display
        continue;
      }
      final contentKey = msg?['contentKey']?.toString();
      final text = (msg?['text']?.toString() ?? '');
      final sender = (msg?['sender']?.toString() ?? (type == 'user' ? 'user' : 'bot'));
      final label = (contentKey != null && contentKey.isNotEmpty) ? 'contentKey:$contentKey' : text;
      turns.add(_ContextMessageView(
        id: n.messageId,
        type: type,
        sender: sender,
        textOrKey: label,
        defaultText: msg?['text']?.toString(),
      ));
    }
    // Window: last N
    final N = config.context.historyBubbles;
    if (turns.length <= N) return turns;
    return turns.sublist(turns.length - N);
  }
}

// Simple condition evaluator compatible with route format
class _Condition {
  final Map<String, dynamic> values;
  _Condition(this.values);

  Future<bool> evaluateCompound(String condition) async {
    // OR first
    if (_containsOutside(condition, '||')) {
      for (final part in _splitOutside(condition, '||')) {
        if (await evaluateCompound(part.trim())) return true;
      }
      return false;
    }
    // AND
    if (_containsOutside(condition, '&&')) {
      for (final part in _splitOutside(condition, '&&')) {
        if (!await evaluateCompound(part.trim())) return false;
      }
      return true;
    }
    return await _evaluateSingle(condition.trim());
  }

  Future<bool> _evaluateSingle(String cond) async {
    final ops = ['>=', '<=', '!=', '==', '>', '<'];
    for (final op in ops) {
      final idx = _findOutside(cond, op);
      if (idx != -1) {
        final left = cond.substring(0, idx).trim();
        final right = cond.substring(idx + op.length).trim();
        final lv = await _getValueOrParse(left);
        final rv = await _getValueOrParse(right);
        switch (op) {
          case '==':
            return _eq(lv, rv);
          case '!=':
            return !_eq(lv, rv);
          case '>':
            return _num(lv) != null && _num(rv) != null && _num(lv)! > _num(rv)!;
          case '<':
            return _num(lv) != null && _num(rv) != null && _num(lv)! < _num(rv)!;
          case '>=':
            return _num(lv) != null && _num(rv) != null && _num(lv)! >= _num(rv)!;
          case '<=':
            return _num(lv) != null && _num(rv) != null && _num(lv)! <= _num(rv)!;
        }
      }
    }
    // No operator: truthy test on variable
    final v = await _getValueOrParse(cond);
    return _truthy(v);
  }

  bool _containsOutside(String s, String op) => _findOutside(s, op) != -1;

  int _findOutside(String s, String op) {
    bool sQ = false, dQ = false;
    for (int i = 0; i <= s.length - op.length; i++) {
      final ch = s[i];
      if (ch == "'" && !dQ) sQ = !sQ;
      if (ch == '"' && !sQ) dQ = !dQ;
      if (!sQ && !dQ && s.substring(i, i + op.length) == op) return i;
    }
    return -1;
  }

  List<String> _splitOutside(String s, String op) {
    final parts = <String>[];
    int last = 0;
    bool sQ = false, dQ = false;
    for (int i = 0; i <= s.length - op.length; i++) {
      final ch = s[i];
      if (ch == "'" && !dQ) sQ = !sQ;
      if (ch == '"' && !sQ) dQ = !dQ;
      if (!sQ && !dQ && s.substring(i, i + op.length) == op) {
        parts.add(s.substring(last, i));
        last = i + op.length;
      }
    }
    parts.add(s.substring(last));
    return parts;
  }

  Future<dynamic> _getValueOrParse(String token) async {
    // Try variable lookup if contains dot
    if (token.contains('.')) {
      final v = values[token];
      if (v != null) return v;
    }
    return _parseLiteral(token);
  }

  dynamic _parseLiteral(String s) {
    final t = s.trim();
    if (t == 'null') return null;
    if (t == 'true') return true;
    if (t == 'false') return false;
    if ((t.startsWith('"') && t.endsWith('"')) || (t.startsWith("'") && t.endsWith("'"))) {
      return t.substring(1, t.length - 1);
    }
    final i = int.tryParse(t);
    if (i != null) return i;
    final d = double.tryParse(t);
    if (d != null) return d;
    return t; // bare token treated as string
  }

  num? _num(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }

  bool _eq(dynamic a, dynamic b) {
    if (a == b) return true;
    final an = _num(a), bn = _num(b);
    if (an != null && bn != null) return an == bn;
    if (a != null && b != null) return a.toString() == b.toString();
    return false;
  }

  bool _truthy(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v.isNotEmpty;
    if (v is List) return v.isNotEmpty;
    if (v is Map) return v.isNotEmpty;
    return true;
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
    final system = '${config.promptCfg.systemMessage} '
        'Write multiple alternative lines for the specified contentKey. '
        'Keep placeholders like {user.name} exactly unchanged. '
        'Use ||| to split long messages into multiple bubbles (max ${config.gen.maxBubblesPerLine}). '
        '${config.style.forbidEmojis ? 'Do not use emojis.' : ''} '
        'Tone: ${config.style.tone.join(', ')}. Concise, natural, no marketing fluff.';

    bool anyNodeExamples = false;
    final context = contextSnapshot.map((m) {
      final isKey = m.textOrKey.startsWith('contentKey:');
      final ref = m.textOrKey; // keep same string label
      final Map<String, dynamic> entry = <String, dynamic>{
        'sender': m.sender,
        'type': m.type,
        'ref': ref,
      };
      if (m.defaultText != null && m.defaultText!.isNotEmpty) {
        entry['default'] = m.defaultText;
      }
      if (config.context.includeNodeSamples && isKey) {
        final key = m.textOrKey.substring('contentKey:'.length);
        final samples = _sampleLinesForContentKeySync(
          key,
          config.context.samplesPerNode,
          forbidEmojis: config.style.forbidEmojis,
        );
        if (samples.isNotEmpty) {
          anyNodeExamples = true;
          entry['examples'] = samples;
        }
      }
      return entry;
    }).toList();

    final prompt = {
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
      if (!(config.context.preferNodeSamples && anyNodeExamples) && config.context.includeSiblingExemplars)
        'exemplars': {
          'existingVariants': existingVariants,
          'siblingExemplars': siblingExemplars.take(config.context.maxExemplars).toList(),
        },
      'output_format': {
        'type': 'json',
        'schema': {'variants': ['string']}
      }
    };
    return prompt;
  }
}

List<String> _sampleLinesForContentKeySync(String key, int k, {bool forbidEmojis = false}) {
  try {
    final ck = _ContentKey.parse(key);
    if (!ck.isValid) return const [];
    final path = ck.toFilePath();
    final f = File(path);
    if (!f.existsSync()) return const [];
    final raw = f.readAsLinesSync().map((e) => e.trim()).where((e) => e.isNotEmpty);
    final lines = <String>[];
    for (final l in raw) {
      if (forbidEmojis && !_isAscii(l)) continue;
      lines.add(l);
    }
    if (lines.isEmpty) return const [];
    return lines.take(k).toList();
  } catch (_) {
    return const [];
  }
}

bool _isAscii(String s) {
  for (final code in s.runes) {
    if (code > 0x7F) return false;
  }
  return true;
}

// ---------------- Generator (LLM REST) ----------------

class _GenResult {
  final List<String> variants;
  final Map<String, dynamic> raw;
  final Map<String, dynamic> request; // full request body sent to provider
  _GenResult(this.variants, this.raw, this.request);
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
      final request = {
        'model': config.provider.model,
        'temperature': config.gen.temperature,
        'top_p': config.gen.topP,
        'n': config.gen.numVariants,
        'prompt': prompt,
      };
      return _GenResult(variants, {
        'mock': true,
        'prompt': prompt,
        'model': config.provider.model,
      }, request);
    }

    final apiKey = Platform.environment[config.provider.apiKeyEnv] ?? '';
    if (apiKey.isEmpty) {
      throw Exception('Missing API key env: ${config.provider.apiKeyEnv}');
    }

    final client = HttpClient();
    client.connectionTimeout = Duration(milliseconds: config.provider.timeoutMs);

    // Build request based on provider
    Uri uri;
    String requestBody;
    Map<String, dynamic> payloadObj;
    bool includeSampling = config.gen.includeSamplingParams;
    if (config.provider.name == 'openai-chat') {
      // OpenAI Chat Completions API
      final base = config.provider.baseUrl.isNotEmpty
          ? config.provider.baseUrl
          : 'https://api.openai.com/v1/chat/completions';
      uri = Uri.parse(base);
      payloadObj = {
        'model': config.provider.model,
        'n': 1, // single JSON object with variants
        // Some newer OpenAI models expect max_completion_tokens instead of max_tokens
        'max_completion_tokens': config.gen.maxTokens,
        // JSON mode to enforce valid JSON response
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'system',
            'content': (prompt['system'] ?? '').toString(),
          },
          {
            'role': 'user',
            'content': jsonEncode(prompt), // provide structured task/context as JSON string
          },
        ],
      };
      if (includeSampling) {
        payloadObj['temperature'] = config.gen.temperature;
        payloadObj['top_p'] = config.gen.topP;
      }
      requestBody = jsonEncode(payloadObj);
    } else {
      // Generic JSON contract: { model, temperature, top_p, prompt: <object> }
      uri = Uri.parse(config.provider.baseUrl);
      payloadObj = {
        'model': config.provider.model,
        'temperature': config.gen.temperature,
        'top_p': config.gen.topP,
        'n': config.gen.numVariants,
        'prompt': prompt,
      };
      requestBody = jsonEncode(payloadObj);
    }

    for (int attempt = 0;; attempt++) {
      try {
        final req = await client.postUrl(uri);
        req.headers.set('content-type', 'application/json');
        req.headers.set('authorization', 'Bearer $apiKey');
        req.write(requestBody);
        final res = await req.close();
        final responseBody = await utf8.decodeStream(res);
        if (res.statusCode >= 200 && res.statusCode < 300) {
          final obj = jsonDecode(responseBody) as Map<String, dynamic>;
          final variants = _extractVariants(obj);
          return _GenResult(variants, obj, payloadObj);
        } else {
          // Handle OpenAI parameter compatibility gracefully
          if (res.statusCode == 400) {
            try {
              final err = jsonDecode(responseBody) as Map<String, dynamic>;
              final em = (err['error'] as Map?)?.cast<String, dynamic>();
              final param = em?['param']?.toString() ?? '';
              final code = em?['code']?.toString() ?? '';
              if ((param == 'temperature' || param == 'top_p') && includeSampling) {
                // Retry once without sampling params
                includeSampling = false;
                // Rebuild request body without temperature/top_p
                if (config.provider.name == 'openai-chat') {
                  payloadObj.remove('temperature');
                  payloadObj.remove('top_p');
                  requestBody = jsonEncode(payloadObj);
                }
                continue;
              }
            } catch (_) {}
          }
          throw HttpException('HTTP ${res.statusCode}: $responseBody');
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
      if (choices.isEmpty) return [];
      final first = choices.first;
      // OpenAI chat: choices[].message.content
      if (first is Map && first['message'] is Map) {
        final content = (first['message'] as Map)['content']?.toString() ?? '';
        try {
          final parsed = jsonDecode(content);
          if (parsed is Map && parsed['variants'] is List) {
            return (parsed['variants'] as List).map((e) => e.toString()).toList();
          }
        } catch (_) {
          // Not JSON; fall through to treat as single variant
        }
        return content.isNotEmpty ? [content] : [];
      }
      // Generic choices with 'text'
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
    required Map<String, dynamic> request,
    required Map<String, dynamic> llmResult,
    required List<String> accepted,
    String? stateFile,
    _ResolvedPath? resolvedPath,
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
      'request': request,
      'response': llmResult,
      'acceptedVariants': accepted,
      if (stateFile != null) 'stateFile': stateFile,
      if (resolvedPath != null)
        'resolvedPath': resolvedPath.toJson(),
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
  // Ensure we start on a new line if the existing file doesn't end with one
  bool needsLeadingNewline = false;
  if (await file.exists()) {
    try {
      final raf = await file.open();
      final len = await raf.length();
      if (len > 0) {
        await raf.setPosition(len - 1);
        final last = await raf.read(1);
        if (last.isNotEmpty) {
          final b = last.first;
          // 10 = \n, 13 = \r
          if (b != 10 && b != 13) needsLeadingNewline = true;
        }
      }
      await raf.close();
    } catch (_) {
      // Best-effort; if we can't read, proceed without leading newline
    }
  }

  final sink = file.openWrite(mode: FileMode.append);
  try {
    if (needsLeadingNewline) {
      sink.writeln();
    }
    for (final l in lines) {
      sink.writeln(l.trim());
    }
  } finally {
    await sink.close();
  }
}
