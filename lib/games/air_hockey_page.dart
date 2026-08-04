import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/game_header.dart';

class AirHockeyPage extends StatefulWidget { const AirHockeyPage({super.key}); @override State<AirHockeyPage> createState()=>_AirHockeyPageState(); }
class _AirHockeyPageState extends State<AirHockeyPage> with SingleTickerProviderStateMixin {
  final confettiKey=GlobalKey<ConfettiOverlayState>(); late final AnimationController clock;
  final Stopwatch _physicsClock=Stopwatch();final Map<int,_PointerSample> _pointerSamples=<int,_PointerSample>{};final Map<int,bool> _pointerLower=<int,bool>{};
  Offset puck=const Offset(.5,.5),velocity=const Offset(.24,.34),bottom=const Offset(.5,.84),top=const Offset(.5,.16),bottomVelocity=Offset.zero,topVelocity=Offset.zero;int bottomScore=0,topScore=0,_lastMicros=0;double _slowTime=0;bool bot=true,playing=true,bottomContact=false,topContact=false;
  @override void initState(){super.initState();_physicsClock.start();clock=AnimationController(vsync:this,duration:const Duration(seconds:1))..addListener(_tick)..repeat();}
  void _tick(){
    if(!mounted||!playing)return;
    final now=_physicsClock.elapsedMicroseconds;
    if(_lastMicros==0){_lastMicros=now;return;}
    final dt=((now-_lastMicros)/1000000).clamp(.001,.034).toDouble();_lastMicros=now;
    var p=puck+velocity*dt,v=velocity*pow(.985,dt*60).toDouble();
    if(bot&&p.dy<.64){
      final attacking=p.dy<.46;
      final targetX=(p.dx+v.dx*(attacking ? .10 : .18)).clamp(.10,.90).toDouble();
      final targetY=(attacking ? (p.dy+.045).clamp(.10,.39) : .16).toDouble();
      final delta=Offset(targetX-top.dx,targetY-top.dy);
      final maxStep=(attacking?1.15:.72)*dt;
      final step=delta.distance>maxStep?delta/delta.distance*maxStep:delta;
      final old=top;top=Offset((top.dx+step.dx).clamp(.10,.90),(top.dy+step.dy).clamp(.08,.43));topVelocity=(top-old)/dt;
    }else if(bot){topVelocity*=pow(.20,dt).toDouble();}
    const radius=.042;
    if(p.dx<radius||p.dx>1-radius){v=Offset(-v.dx*.94,v.dy);p=Offset(p.dx.clamp(radius,1-radius),p.dy);SoundService.instance.play('pop.wav',volumeBoost:1.55);}
    final inGoal=p.dx>.31&&p.dx<.69;
    if(!inGoal&&p.dy<radius){v=Offset(v.dx,-v.dy*.94);p=Offset(p.dx,radius);SoundService.instance.play('pop.wav',volumeBoost:1.55);}
    if(!inGoal&&p.dy>1-radius){v=Offset(v.dx,-v.dy*.94);p=Offset(p.dx,1-radius);SoundService.instance.play('pop.wav',volumeBoost:1.55);}
    final lowerHit=_collide(bottom,p,bottomVelocity,bottomContact,v);p=lowerHit.position;v=lowerHit.velocity;bottomContact=lowerHit.contact;
    final upperHit=_collide(top,p,topVelocity,topContact,v);p=upperHit.position;v=upperHit.velocity;topContact=upperHit.contact;
    bottomVelocity*=pow(.08,dt).toDouble();topVelocity*=pow(.08,dt).toDouble();
    if(p.dy<-.05&&inGoal){bottomScore++;_goal(true);return;}if(p.dy>1.05&&inGoal){topScore++;_goal(false);return;}
    if(v.distance<.075){_slowTime+=dt;}else{_slowTime=0;}
    if(_slowTime>.85){
      final direction=p.dy<.5?1.0:-1.0;
      v=Offset((.5-p.dx)*.45,direction*.30);
      _slowTime=0;
    }
    setState((){puck=p;velocity=v;});
  }
  ({Offset position,Offset velocity,bool contact}) _collide(Offset paddle,Offset p,Offset paddleSpeed,bool wasTouching,Offset current){
    final d=p-paddle,distance=d.distance;if(distance>=.108||distance==0)return(position:p,velocity:current,contact:false);final n=d/distance;
    if(wasTouching)return(position:p,velocity:current,contact:true);
    final relative=current-paddleSpeed,approach=relative.dx*n.dx+relative.dy*n.dy;
    if(approach>=0&&paddleSpeed.distance<.08)return(position:p,velocity:current,contact:true);
    var result=relative-n*(1.96*approach)+paddleSpeed*1.42;
    final minimum=paddle==top&&bot ? .48 : .25;
    if(result.distance<minimum)result=n*minimum+paddleSpeed*.72;
    result=_limit(result,2.65);
    SoundService.instance.play('pop.wav',volumeBoost:1.8);
    return(position:paddle+n*.109,velocity:result,contact:true);
  }
  void _goal(bool human){SoundService.instance.play('chime.wav',volumeBoost:1.35);if(bottomScore>=5||topScore>=5){playing=false;confettiKey.currentState?.burst(count:34);SoundService.instance.play('win.wav');}setState((){puck=const Offset(.5,.5);velocity=Offset((Random().nextDouble()-.5)*.32,human ? .34 : -.34);bottomContact=topContact=false;_slowTime=0;});}
  void _reset(){setState((){bottomScore=0;topScore=0;playing=true;puck=const Offset(.5,.5);velocity=const Offset(.24,.34);bottom=const Offset(.5,.84);top=const Offset(.5,.16);bottomVelocity=Offset.zero;topVelocity=Offset.zero;bottomContact=topContact=false;_slowTime=0;_lastMicros=_physicsClock.elapsedMicroseconds;});}
  Offset _limit(Offset value,double maximum)=>value.distance>maximum?value/value.distance*maximum:value;
  Offset _normalizedPosition(PointerEvent e,BoxConstraints c)=>Offset((e.localPosition.dx/c.maxWidth).clamp(.1,.9),(e.localPosition.dy/c.maxHeight).clamp(.08,.92));
  void _pointerDown(PointerDownEvent e,BoxConstraints c){final position=_normalizedPosition(e,c),lower=position.dy>=.5;if(!lower&&bot)return;_pointerLower[e.pointer]=lower;_pointerSamples[e.pointer]=_PointerSample(position,e.timeStamp);if(lower){bottom=Offset(position.dx,position.dy.clamp(.56,.92));bottomVelocity=Offset.zero;}else{top=Offset(position.dx,position.dy.clamp(.08,.44));topVelocity=Offset.zero;}}
  void _pointerMove(PointerMoveEvent e,BoxConstraints c){final lower=_pointerLower[e.pointer],sample=_pointerSamples[e.pointer];if(lower==null||sample==null)return;final raw=_normalizedPosition(e,c);final next=lower?Offset(raw.dx,raw.dy.clamp(.56,.92)):Offset(raw.dx,raw.dy.clamp(.08,.44));final dt=(e.timeStamp-sample.time).inMicroseconds/1000000;if(dt<=0)return;final instant=_limit((next-sample.position)/dt,3.2);if(lower){bottomVelocity=bottomVelocity*.28+instant*.72;bottom=next;}else{topVelocity=topVelocity*.28+instant*.72;top=next;}_pointerSamples[e.pointer]=_PointerSample(next,e.timeStamp);}
  void _pointerUp(PointerEvent e){_pointerSamples.remove(e.pointer);_pointerLower.remove(e.pointer);}
  @override void dispose(){clock.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>ConfettiOverlay(key:confettiKey,child:Padding(padding:const EdgeInsets.fromLTRB(14,8,14,12),child:Column(children:[
    GameHeader(title:'الهوكي الهوائي',subtitle:playing?'الأول الذي يسجل 5 أهداف يفوز':(bottomScore>topScore?'فاز اللاعب 1 🎉':'فاز ${bot?'الروبوت':'اللاعب 2'} 🎉'),color:const Color(0xFF0891B2),onReset:_reset),
    const SizedBox(height:7),Row(children:[Expanded(child:ChoiceChip(label:const Text('ضد الروبوت'),selected:bot,onSelected:(_){bot=true;_reset();})),const SizedBox(width:8),Expanded(child:ChoiceChip(label:const Text('مع صديق'),selected:!bot,onSelected:(_){bot=false;_reset();}))]),const SizedBox(height:7),
    Row(mainAxisAlignment:MainAxisAlignment.center,children:[_Score(name:'اللاعب 1',score:bottomScore,color:const Color(0xFF22D3EE)),const SizedBox(width:18),_Score(name:bot?'الروبوت':'اللاعب 2',score:topScore,color:const Color(0xFFF472B6))]),const SizedBox(height:8),
    Expanded(child:LayoutBuilder(builder:(context,c)=>Listener(onPointerDown:(e)=>_pointerDown(e,c),onPointerMove:(e)=>_pointerMove(e,c),onPointerUp:_pointerUp,onPointerCancel:_pointerUp,child:CustomPaint(size:Size(c.maxWidth,c.maxHeight),painter:_HockeyPainter(puck,bottom,top)))))
  ])));
}
class _PointerSample{const _PointerSample(this.position,this.time);final Offset position;final Duration time;}
class _Score extends StatelessWidget{const _Score({required this.name,required this.score,required this.color});final String name;final int score;final Color color;@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:7),decoration:BoxDecoration(color:color.withAlpha(25),border:Border.all(color:color),borderRadius:BorderRadius.circular(16)),child:Text('$name  $score',style:TextStyle(color:color,fontWeight:FontWeight.w900,fontSize:16)));}
class _HockeyPainter extends CustomPainter{const _HockeyPainter(this.puck,this.bottom,this.top);final Offset puck,bottom,top;Offset p(Offset x,Size s)=>Offset(x.dx*s.width,x.dy*s.height);@override void paint(Canvas c,Size s){final rect=Offset.zero&s;c.drawRRect(RRect.fromRectAndRadius(rect,const Radius.circular(30)),Paint()..shader=const LinearGradient(colors:[Color(0xFF071B33),Color(0xFF0B3556),Color(0xFF071B33)],begin:Alignment.topCenter,end:Alignment.bottomCenter).createShader(rect));final line=Paint()..color=const Color(0x8838BDF8)..style=PaintingStyle.stroke..strokeWidth=3;c.drawLine(Offset(0,s.height/2),Offset(s.width,s.height/2),line);c.drawCircle(Offset(s.width/2,s.height/2),s.width*.14,line);_goal(c,s,top:true,color:const Color(0xFFF472B6));_goal(c,s,top:false,color:const Color(0xFF22D3EE));_disc(c,p(top,s),s.width*.065,const Color(0xFFF472B6));_disc(c,p(bottom,s),s.width*.065,const Color(0xFF22D3EE));_disc(c,p(puck,s),s.width*.035,Colors.white);}
void _goal(Canvas c,Size s,{required bool top,required Color color}){final y=top?0.0:s.height;final inward=top?1.0:-1.0;final width=s.width*.38;final left=(s.width-width)/2;final frame=Paint()..color=color..style=PaintingStyle.stroke..strokeWidth=6..strokeCap=StrokeCap.round;c.drawLine(Offset(left,y),Offset(left,y+inward*24),frame);c.drawLine(Offset(left+width,y),Offset(left+width,y+inward*24),frame);c.drawLine(Offset(left,y+inward*24),Offset(left+width,y+inward*24),frame);final net=Paint()..color=color.withAlpha(95)..strokeWidth=1.2;for(var i=1;i<6;i++){final x=left+width*i/6;c.drawLine(Offset(x,y),Offset(x,y+inward*24),net);}for(var i=1;i<3;i++){final ny=y+inward*24*i/3;c.drawLine(Offset(left,ny),Offset(left+width,ny),net);}}
void _disc(Canvas c,Offset center,double r,Color color){c.drawCircle(center,r,Paint()..color=const Color(0x55000000)..maskFilter=const MaskFilter.blur(BlurStyle.normal,8));c.drawCircle(center,r,Paint()..shader=RadialGradient(colors:[Colors.white,color]).createShader(Rect.fromCircle(center:center,radius:r)));} @override bool shouldRepaint(covariant _HockeyPainter old)=>true;}
