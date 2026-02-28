import 'package:flutter/material.dart';
import 'media_badge.dart'; import 'rating_stars.dart';
class MediaCard extends StatelessWidget{
  final String title,type; final int? year; final String? imageUrl; final double? rating; final String? subtitle; final String? blurb; final double? imageWidth; final VoidCallback? onTap;
  const MediaCard({super.key, required this.title, required this.type, this.year, this.imageUrl, this.rating, this.subtitle, this.blurb, this.imageWidth, this.onTap});
  @override Widget build(BuildContext context){
    final t=Theme.of(context).textTheme; final muted=Theme.of(context).colorScheme.onSurfaceVariant; final imgW=imageWidth??96;
    return Card(clipBehavior: Clip.antiAlias, child: InkWell(onTap:onTap, child: Row(children:[
      SizedBox(width:imgW, height: imgW*4/3, child: imageUrl!=null?Image.network(imageUrl!, fit:BoxFit.cover):Container(color:Theme.of(context).colorScheme.surfaceContainerHighest, child: const Icon(Icons.image))),
      Expanded(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
        Row(children:[MediaBadge(type:type), const SizedBox(width:8), if(year!=null) Text('$year')]),
        const SizedBox(height:4),
        Text(title, style:t.titleMedium, maxLines:2, overflow: TextOverflow.ellipsis),
        if(subtitle!=null)...[const SizedBox(height:6), Text(subtitle!, maxLines:2, overflow: TextOverflow.ellipsis)],
        if(blurb!=null && blurb!.isNotEmpty)...[const SizedBox(height:6), Text(blurb!, style: t.bodySmall?.copyWith(color: muted), maxLines:2, overflow: TextOverflow.ellipsis)],
        const SizedBox(height:8),
        if(rating!=null) RatingStars(rating: rating!),
      ]))),
    ])));
  }
}
