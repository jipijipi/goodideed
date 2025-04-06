import 'dart:math';
import 'package:tristopher_app/models/user_model.dart';

/// Service to generate Tristopher's dialogue based on user state and context
class StoryService {
  // Introduction messages
  List<String> getIntroductionMessages() {
    return [
      "Hello human. I'm Tristopher, your personal de-motivator.",
      "I'm here to watch you fail at your goals. It's what humans do best, after all.",
      "Let's set up your inevitable disappointment, shall we?"
    ];
  }
  
  // Get a message asking for the user's name
  String getAskNameMessage() {
    final options = [
      "First, what should I call you? Not that it matters much...",
      "I'll need something to put on your failure certificate. Your name?",
      "Let's start with your name. I need to know who I'm dealing with."
    ];
    
    return _getRandomMessage(options);
  }
  
  // Get a message welcoming the user by name
  String getWelcomeMessage(String name) {
    final options = [
      "Ah, $name. Another human with dreams bigger than their willpower.",
      "Welcome, $name. Let's see how long you last.",
      "$name. Hmm. I've seen worse names. Let's continue."
    ];
    
    return _getRandomMessage(options);
  }
  
  // Get a message explaining the "Just One Thing" concept
  String getExplainOneThingMessage() {
    final options = [
      "Let me explain how this works. You'll choose ONE habit to focus on. Just one. Even that will probably be too much for you.",
      "Here's the deal: pick ONE thing you want to accomplish daily. One simple thing that even you might be able to handle.",
      "This app focuses on a single daily goal. 'Just One Thing.' The science says that's all humans can handle. And even that's questionable."
    ];
    
    return _getRandomMessage(options);
  }
  
  // Get a message asking for the user's goal
  String getAskGoalMessage() {
    final options = [
      "So, what's this ONE thing you'll inevitably fail at?",
      "What single daily goal do you want to pretend you'll accomplish?",
      "Tell me the ONE habit you'd like to build. Make it specific and achievable. Not that it'll help much."
    ];
    
    return _getRandomMessage(options);
  }
  
  // Get a message responding to the user's goal
  String getGoalResponseMessage(String goal) {
    final options = [
      "\"$goal\" - Ambitious for someone like you. But I'll play along.",
      "\"$goal\" - How predictable. Well, at least you're consistent in your mediocrity.",
      "\"$goal\" - Interesting choice. Not particularly inspired, but it's yours to fail at."
    ];
    
    return _getRandomMessage(options);
  }
  
  // Get a message explaining the anti-charity concept
  String getExplainAntiCharityMessage() {
    final options = [
      "Now for the fun part. You'll set up a monetary stake. Every time you fail, that money goes to a cause you HATE. Delicious, isn't it?",
      "Here's where it gets interesting. You'll put money on the line. Fail, and it goes to an organization you despise. Humans hate losing money more than they like succeeding.",
      "Let's add some consequences to your inevitable failure. You'll stake money that will go to an anti-charity - a cause you strongly oppose - when you fail."
    ];
    
    return _getRandomMessage(options);
  }
  
  // Get a message asking about setting a stake
  String getAskAboutStakeMessage() {
    final options = [
      "So, want to set a stake? Or are you too scared of losing your precious money?",
      "Ready to put your money where your mouth is? Or would you rather just make empty promises to yourself?",
      "Shall we set a monetary stake? Or do you prefer the comfort of consequence-free failure?"
    ];
    
    return _getRandomMessage(options);
  }
  
  // Get a message asking for stake amount
  String getAskStakeAmountMessage() {
    final options = [
      "How much money are you willing to lose? Enter an amount.",
      "Place your bet. How much are you willing to stake on your discipline?",
      "Enter your stake amount. Make it hurt just enough."
    ];
    
    return _getRandomMessage(options);
  }
  
  // Get a message responding to stake amount
  String getStakeAmountResponseMessage(double amount) {
    if (amount < 5) {
      return "Really? $amount? That's barely enough to notice. But fine, it's your meaningless gesture.";
    } else if (amount < 20) {
      return "$amount. At least it's something. Still not enough to really motivate you, but what do I know?";
    } else {
      return "$amount! Now we're talking. This might actually sting when you fail.";
    }
  }
  
  // Get a message asking to choose an anti-charity
  String getChooseAntiCharityMessage() {
    final options = [
      "Choose where your money will go when you fail. Pick something that makes your skin crawl:",
      "Select your anti-charity. This is where your cash goes every time you skip \"just one thing\":",
      "Time to choose the beneficiary of your future failures:"
    ];
    
    return _getRandomMessage(options);
  }
  
  // Get a message about the 66-day challenge
  String get66DayChallengeMessage() {
    final options = [
      "Science says it takes 66 days to form a habit. Want to commit to a 66-day challenge? (You won't make it, but it might be amusing to watch you try.)",
      "Interested in the 66-day challenge? Research shows that's how long it takes to form a solid habit. Most humans give up by day 4.",
      "Care to enroll in the 66-day habit formation program? I'll track your progress, though I expect it to be brief."
    ];
    
    return _getRandomMessage(options);
  }
  
  // Get a message for after onboarding completion
  String getOnboardingCompleteMessage() {
    final options = [
      "Setup complete. Your journey of disappointment begins now.",
      "All set. Let's start the countdown to your first failure.",
      "Ready to begin. I'm already calculating the probability of your failure. Spoiler: It's high."
    ];
    
    return _getRandomMessage(options);
  }
  
  // Get a message asking if the user completed their goal yesterday
  String getDailyCheckInMessage(UserModel user) {
    final goalTitle = user.goalTitle ?? "your goal";
    
    final options = [
      "Well? Did you actually do \"$goalTitle\" yesterday?",
      "Time for your daily confession. Did you complete \"$goalTitle\" yesterday?",
      "Another day, another check-in. Did you manage to do \"$goalTitle\" yesterday?"
    ];
    
    return _getRandomMessage(options);
  }
  
  // Get a success response message
  String getSuccessResponseMessage(UserModel user) {
    final streak = user.streakCount + 1; // +1 because this will be the new streak
    
    if (streak == 1) {
      final options = [
        "Huh. Congratulations on doing the bare minimum, I guess.",
        "Day one complete. Don't get used to success.",
        "One day down. Let's see if you can handle day two."
      ];
      return _getRandomMessage(options);
    } else if (streak < 5) {
      final options = [
        "A $streak-day streak? Marginally impressive. For you.",
        "You've managed $streak days in a row. The law of averages suggests failure is imminent.",
        "$streak days. Not terrible. Not good either, but not terrible."
      ];
      return _getRandomMessage(options);
    } else if (streak < 10) {
      final options = [
        "A $streak-day streak? I'm... somewhat surprised. Still expecting collapse any day now.",
        "$streak days consistent. Statistical anomaly or genuine improvement? I'm betting on the former.",
        "Day $streak of your streak. Every successful day brings you closer to your inevitable failure."
      ];
      return _getRandomMessage(options);
    } else {
      final options = [
        "A $streak-day streak? I'm reluctantly impressed. Almost suspicious.",
        "$streak days consistent. You're defying my expectations. How irritating.",
        "Day $streak. Either you're actually building a habit or you're lying to me. Both would be typical human behavior."
      ];
      return _getRandomMessage(options);
    }
  }
  
  // Get a failure response message
  String getFailureResponseMessage(UserModel user) {
    final antiCharity = user.antiCharityChoice ?? "your anti-charity";
    final stakeAmount = user.formattedStakeAmount;
    
    final options = [
      "Failure, as predicted. $stakeAmount transferred to $antiCharity. I'd say I'm disappointed, but that would imply I expected better.",
      "And there it is. The inevitable collapse. $stakeAmount is now supporting $antiCharity. How does it feel?",
      "Streak reset to zero. $stakeAmount donated to $antiCharity. This is the part where I pretend to be surprised."
    ];
    
    return _getRandomMessage(options);
  }
  
  // Get a message asking if the user wants to increase their stake
  String getIncreaseStakeMessage(UserModel user) {
    final currentStake = user.formattedStakeAmount;
    
    final options = [
      "Feeling confident? Want to increase your stake from $currentStake?",
      "Care to raise the stakes? Currently you're risking $currentStake. Not very daring, is it?",
      "Your current stake is $currentStake. Increase it to show you're serious. Or keep it low if you're planning to fail."
    ];
    
    return _getRandomMessage(options);
  }
  
  // Get a message asking if the user wants to set a new stake after failure
  String getSetNewStakeAfterFailureMessage() {
    final options = [
      "Want to set a new stake? Or are you giving up already?",
      "Care to try again with a new stake? Or is this where your motivation ends?",
      "Set a new stake or walk away. Your choice, though both paths eventually lead to the same place."
    ];
    
    return _getRandomMessage(options);
  }
  
  // Helper function to get a random message from options
  String _getRandomMessage(List<String> options) {
    final random = Random();
    return options[random.nextInt(options.length)];
  }
}
