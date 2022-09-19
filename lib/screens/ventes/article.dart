// ignore_for_file: unnecessary_this, sized_box_for_whitespace, non_constant_identifier_names
import 'package:flutter/material.dart';

class   ArticlesVentes extends StatelessWidget {
  final Elements elmt;
  final VoidCallback delete;
  final VoidCallback edit ;
  const ArticlesVentes({Key? key, required this.elmt, 
  required this.delete, 
  required this.edit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.sell),
        title: Text(elmt.designation),
        subtitle:Container(
          width: 80,child: Row(
            children: [
              Expanded(
                child: Text("Quantié:${elmt.quantite}")
              ),
              Expanded(
                child: Text("Total:${elmt.total} Fcfa"),
              ),
            ],
          ),
        ),
        trailing: Container(
          width: 80,child: Row(
            children: [
              Expanded(
                child: IconButton(icon: const Icon(Icons.edit,color:Colors.blue), onPressed:this.edit),
              ),
              Expanded(
                child: IconButton(icon: const Icon(Icons.delete, color: Colors.red,), onPressed:this.delete),
              ),
            ],
          ),
        )
      
      ),
    );
  }

}
class Elements {
  final String designation;
  final String quantite;
  final String total;
  Elements({required this.designation, required this.quantite,required this.total});
}

