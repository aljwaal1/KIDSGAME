import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/game_header.dart';

class CheckersPage extends StatefulWidget { const CheckersPage({super.key}); @override State<CheckersPage> createState()=>_CheckersPageState(); }
class _Move { const _Move(this.from,this.to,[this.captured]); final int from,to; final int? captured; }

class _CheckersPageState extends State<CheckersPage> {
  final confettiKey=GlobalKey<ConfettiOverlayState>(); final random=Random(); Timer? timer;
  late List<int> board; int player=0; int? selected,winner; bool bot=true;
  @override void initState(){super.initState();_reset();}
  void _reset(){timer?.cancel();board=List<int>.filled(64,0);for(var r=0;r<3;r++)for(var c=0;c<8;c++)if((r+c).isOdd)board[r*8+c]=2;for(var r=5;r<8;r++)for(var c=0;c<8;c++)if((r+c).isOdd)board[r*8+c]=1;setState((){player=0;selected=null;winner=null;});}
  bool _mine(int piece,int p)=>p==0?(piece==1||piece==3):(piece==2||piece==4);
  List<_Move> _pieceMoves(int from,{bool capturesOnly=false}){
    final piece=board[from],r=from~/8,c=from%8,out=<_Move>[];
    final dirs=piece>=3?<int>[-1,1]:<int>[piece==1?-1:1];
    for(final dr in dirs)for(final dc in const [-1,1]){
      final r1=r+dr,c1=c+dc;if(r1<0||r1>7||c1<0||c1>7)continue;final i1=r1*8+c1;
      if(!capturesOnly&&board[i1]==0)out.add(_Move(from,i1));
      final r2=r+dr*2,c2=c+dc*2;if(r2>=0&&r2<8&&c2>=0&&c2<8&&board[i1]!=0&&!_mine(board[i1],player)&&board[r2*8+c2]==0)out.add(_Move(from,r2*8+c2,i1));
    }return out;
  }
  List<_Move> _allMoves(int p){final old=player;player=p;final all=<_Move>[];for(var i=0;i<64;i++)if(_mine(board[i],p))all.addAll(_pieceMoves(i));player=old;final captures=all.where((m)=>m.captured!=null).toList();return captures.isNotEmpty?captures:all;}
  void _tap(int index){if(winner!=null||(bot&&player==1))return;if(selected==null){if(_mine(board[index],player)&&_allMoves(player).any((m)=>m.from==index))setState(()=>selected=index);return;}final valid=_allMoves(player).where((m)=>m.from==selected&&m.to==index).toList();if(valid.isEmpty){setState(()=>selected=_mine(board[index],player)?index:null);return;}_play(valid.first);}
  void _play(_Move m){SoundService.instance.play('move.wav');setState((){var piece=board[m.from];board[m.from]=0;board[m.to]=piece;if(m.captured!=null)board[m.captured!]=0;final row=m.to~/8;if(piece==1&&row==0)board[m.to]=3;if(piece==2&&row==7)board[m.to]=4;if(m.captured!=null&&_pieceMoves(m.to,capturesOnly:true).any((x)=>x.captured!=null)){selected=m.to;return;}selected=null;player=1-player;if(_allMoves(player).isEmpty){winner=1-player;confettiKey.currentState?.burst();SoundService.instance.play('win.wav');}});if(winner==null&&bot&&player==1)_bot();}
  void _bot(){timer?.cancel();timer=Timer(const Duration(milliseconds:650),(){if(!mounted||winner!=null||player!=1)return;final moves=selected!=null?_pieceMoves(selected!,capturesOnly:true).where((m)=>m.captured!=null).toList():_allMoves(1);if(moves.isEmpty)return;final captures=moves.where((m)=>m.captured!=null).toList();_play((captures.isNotEmpty?captures:moves)[random.nextInt((captures.isNotEmpty?captures:moves).length)]);});}
  @override void dispose(){timer?.cancel();super.dispose();}
  @override Widget build(BuildContext context)=>ConfettiOverlay(key:confettiKey,child:Padding(padding:const EdgeInsets.fromLTRB(14,8,14,14),child:Column(children:[
    GameHeader(title:'الداما',subtitle:winner!=null?'فاز ${bot&&winner==1?'الروبوت':'اللاعب ${winner!+1}'} 🎉':bot&&player==1?'الروبوت يفكر...':'دور اللاعب ${player+1}',color:const Color(0xFFB91C1C),onReset:_reset),
    const SizedBox(height:8),Row(children:[Expanded(child:ChoiceChip(label:const Text('ضد الروبوت'),selected:bot,onSelected:(_){bot=true;_reset();})),const SizedBox(width:8),Expanded(child:ChoiceChip(label:const Text('مع صديق'),selected:!bot,onSelected:(_){bot=false;_reset();}))]),const SizedBox(height:12),
    Expanded(child:Center(child:AspectRatio(aspectRatio:1,child:GridView.builder(physics:const NeverScrollableScrollPhysics(),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:8),itemCount:64,itemBuilder:(context,i){final dark=((i~/8+i%8).isOdd),piece=board[i],active=selected==i,target=selected!=null&&_allMoves(player).any((m)=>m.from==selected&&m.to==i);return GestureDetector(onTap:()=>_tap(i),child:Container(decoration:BoxDecoration(color:dark?const Color(0xFF6B3F2A):const Color(0xFFF3D6A4),border:target?Border.all(color:const Color(0xFF22C55E),width:4):null),child:piece==0?null:Padding(padding:const EdgeInsets.all(5),child:DecoratedBox(decoration:BoxDecoration(shape:BoxShape.circle,gradient:LinearGradient(colors:_mine(piece,0)?const [Color(0xFFFF6B6B),Color(0xFFB91C1C)]:const [Color(0xFF60A5FA),Color(0xFF1D4ED8)]),border:Border.all(color:active?Colors.amber:Colors.white,width:active?4:2),boxShadow:const [BoxShadow(color:Color(0x66000000),blurRadius:5,offset:Offset(0,3))]),child:piece>=3?const Icon(Icons.star_rounded,color:Colors.amber):null))),);})))))
  ])));
}