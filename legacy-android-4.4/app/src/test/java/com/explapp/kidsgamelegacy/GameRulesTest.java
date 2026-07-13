package com.explapp.kidsgamelegacy;
import org.junit.Test;
import static org.junit.Assert.*;
public class GameRulesTest {
 @Test public void rewardsIncreaseOnlyForLongStreaks(){
  assertEquals(2,MainActivity.GameRules.starsFor(0));
  assertEquals(2,MainActivity.GameRules.starsFor(3));
  assertEquals(3,MainActivity.GameRules.starsFor(4));
  assertEquals(3,MainActivity.GameRules.starsFor(8));
  assertEquals(5,MainActivity.GameRules.starsFor(9));
 }
}
