enum AudioChannel { ui, action, impact, result, voice }

enum GameSoundEvent {
  uiSelect, uiTap, pieceSelect, pieceMove, pieceDrop, pieceCapture, piecePromote,
  cardFlip, cardMatch, cardMismatch, tileSlide, drawLine, boxComplete, diceRoll,
  tokenStep, ladderClimb, snakeSlide, bubblePop, correctAnswer, wrongAnswer,
  roundComplete, humanVictory, opponentVictory, friendVictory, drawResult,
  hockeyWallHit, hockeyPaddleHit, hockeyGoal, penaltyKick, penaltyNet,
  penaltySave, marbleLaunch, marbleRoll, softMiss, throwWhoosh, stoneCrash,
  stonePickup, stonePlace, blockedMove, reveal, treasureFound, traceStroke,
}

class GameAudioCue {
  const GameAudioCue({required this.asset, required this.channel, required this.gain, this.priority = 1, this.cooldown = Duration.zero});
  final String asset;
  final AudioChannel channel;
  final double gain;
  final int priority;
  final Duration cooldown;
}
