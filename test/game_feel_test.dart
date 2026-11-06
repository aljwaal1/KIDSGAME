import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:kids_games_arena/physics/hockey_simulation.dart';
import 'package:kids_games_arena/services/audio_arbiter.dart';

void main() {
  test('victory resists low-priority feedback until its hold expires', () {
    final arbiter = AudioArbiter();
    final now = DateTime(2026);
    final victory = arbiter.acquire('result', 4, now, const Duration(seconds: 1));
    expect(victory, isNotNull);
    expect(arbiter.acquire('result', 2, now.add(const Duration(milliseconds: 100)), Duration.zero), isNull);
    expect(arbiter.isCurrent('result', victory!), isTrue);
    expect(arbiter.acquire('result', 2, now.add(const Duration(seconds: 2)), Duration.zero), isNotNull);
    expect(arbiter.isCurrent('result', victory), isFalse);
  });
  test('stop invalidates every pending audio request', () {
    final arbiter = AudioArbiter();
    final ticket = arbiter.acquire('impact', 1, DateTime(2026), Duration.zero)!;
    arbiter.invalidateAll();
    expect(arbiter.isCurrent('impact', ticket), isFalse);
  });
  test('hockey separating contact does not reverse or amplify velocity', () {
    final s = HockeySimulation(height: 2);
    s.puck = const Offset(.5, 1.61);
    s.bottom = const Offset(.5, 1.7);
    s.bottomTarget = s.bottom;
    s.velocity = const Offset(0, -.3);
    s.step(1 / 240);
    expect(s.velocity.dy, lessThan(0));
    expect(s.velocity.distance, lessThanOrEqualTo(.3));
    expect(s.events.where((e) => e == HockeyEvent.paddle), isEmpty);
  });
  test('hockey hitbox matches a circle in a tall viewport', () {
    final s = HockeySimulation(height: 2);
    s.bot = false;
    s.bottom = const Offset(.5, 1.7);
    s.bottomTarget = s.bottom;
    s.puck = const Offset(.5, 1.57); // 0.13 > radii sum 0.10.
    s.velocity = const Offset(0, .1);
    s.step(1 / 240);
    expect(s.events, isEmpty);
    expect(s.velocity.dy, greaterThan(0));
  });
  test('hockey substeps prevent tunnelling and cap puck speed', () {
    final s = HockeySimulation(height: 2)..bot = false;
    s.puck = const Offset(.94, 1);
    s.velocity = const Offset(1.4, 0);
    s.step(.1);
    expect(s.puck.dx, lessThanOrEqualTo(.965));
    expect(s.velocity.dx, lessThan(0));
    expect(s.velocity.distance, lessThanOrEqualTo(1.45));
  });
  test('a scored puck cannot score twice without a new serve', () {
    final s = HockeySimulation(height: 2)..bot = false;
    s.puck = const Offset(.5, -.02);
    s.velocity = const Offset(0, -.5);
    s.step(.1);
    expect(s.scorer, 0);
    s.step(.1);
    expect(s.scorer, 0);
    expect(s.events.where((e) => e == HockeyEvent.goal).length, 0);
  });
  test('free motion is stable at 30 and 120 frames per second', () {
    final a = HockeySimulation(height: 2)..bot = false;
    final b = HockeySimulation(height: 2)..bot = false;
    for (var i = 0; i < 15; i++) { a.step(1 / 30); }
    for (var i = 0; i < 60; i++) { b.step(1 / 120); }
    expect((a.puck - b.puck).distance, lessThan(.002));
    expect((a.velocity - b.velocity).distance, lessThan(.002));
  });
}
