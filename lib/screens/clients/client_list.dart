// ignore_for_file: unused_local_variable, non_constant_identifier_names, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:tocmanager/models/Clients.dart';
import 'package:tocmanager/screens/clients/ajouter_client.dart';

import '../../models/api_response.dart';
import '../../services/clients_services.dart';
import '../../services/user_service.dart';
import '../suscribe_screen/suscribe_screen.dart';

class ListClient extends StatefulWidget {
  const ListClient({super.key});

  @override
  State<ListClient> createState() => _ListClientState();
}

List<dynamic> clients = [];

class _ListClientState extends State<ListClient> {
  bool isNotSuscribe = false;
  bool isLoading = true;
  @override
  void initState() {
    readclient();
    checkSuscribe();
    super.initState();
  }

    Future<void> checkSuscribe() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await SuscribeCheck(compagnie_id);
    if (response.data == null) {
      ApiResponse response = await SuscribeGrace(compagnie_id);
      if (response.statusCode == 200) {
        if (response.status == "error") {
          setState(() {
            isNotSuscribe = true;
          });
        } else if (response.status == "success") {
          var data = response.data as Map<String, dynamic>;
          var hasEndGrace = data['hasEndGrace'];
          var graceEndDate = data['graceEndDate'];
          if (hasEndGrace == false && graceEndDate != null) {
            setState(() {
              isNotSuscribe = true;
            });
          }
        }
      }
    }
  }

  Future<void> readclient() async {
    int compagnie_id = await getCompagnie_id();
    ApiResponse response = await ReadClients(compagnie_id);
    if (response.error == null) {
      if (response.statusCode == 200) {
        List<dynamic> data = response.data as List<dynamic>;
        clients = data.map((p) => Clients.fromJson(p)).toList();
        setState(() {
          isLoading = false;
        });
      }
    } else {
      if (response.statusCode == 403) {
        setState(() {
          isNotSuscribe = true;
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return isNotSuscribe == true
        ? const SuscribePage()
        : Container(
            child: isLoading == true
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: SingleChildScrollView(
                      child: PaginatedDataTable(
                        onRowsPerPageChanged: (perPage) {},
                        rowsPerPage: 10,
                        columns: const [
                          DataColumn(label: Center(child: Text("Nom"))),
                          DataColumn(label: Center(child: Text("Email"))),
                          DataColumn(label: Center(child: Text("Numéro"))),
                          DataColumn(label: Center(child: Text("Editer"))),
                          DataColumn(label: Center(child: Text("Effacer"))),
                        ],
                        source: DataTableRow(
                          data: clients,
                          onDelete: _deleteClient,
                          // onEdit: _showFormDialog,
                        ),
                      ),
                    ),
                  ),
          );
  }

  void _deleteClient(client_id) async {
    bool sendMessage = false;
    int compagnie_id = await getCompagnie_id();
    String? message;
    String color = "red";
    ApiResponse response = await DeleteClients(compagnie_id, client_id);
    if (response.statusCode == 200) {
      if (response.status == "success") {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AjouterClientPage()));

        message = "Supprimé avec succès";
        setState(() {
          sendMessage = true;
          color = "green";
        });
      } else {
        message = "La suppression a échouée";
        setState(() {
          sendMessage = true;
        });
      }
    } else if (response.statusCode == 403) {
      message = "Vous n'êtes pas autorisé à effectuer cette action";
      setState(() {
        sendMessage = true;
      });
    } else if (response.statusCode == 500) {
      print("object");
      message = "La suppression a échouée !";
      setState(() {
        sendMessage = true;
      });
    } else {
      message = "La suppression a échouée !";
      setState(() {
        sendMessage = true;
      });
    }
    if (sendMessage == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor:
              color == "green" ? Colors.green[800] : Colors.red[800],
          content: SizedBox(
            width: double.infinity,
            height: 20,
            child: Center(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          duration: const Duration(milliseconds: 2000),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class DataTableRow extends DataTableSource {
  final List<dynamic> data;
  final Function(int) onDelete;
  // final Function(int?, int?, String?) onEdit;
  DataTableRow({required this.data, required this.onDelete});

  @override
  DataRow getRow(int index) {
    final Clients client = clients[index];
    return DataRow.byIndex(
      index: index,
      cells: <DataCell>[
        DataCell(Center(child: Text(client.name.toString()))),
        DataCell(Center(child: Text(client.email.toString()))),
        DataCell(Center(child: Text(client.phone.toString()))),
        DataCell(Center(
          child: IconButton(
              icon: const Icon(
                Icons.edit,
                color: Colors.blue,
              ),
              onPressed: () async {
                // onEdit(
                //   category.id,

                //   category.name.toString(),
                // );
              }),
        )),
        DataCell(Center(
          child: IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
              onPressed: () async {
                onDelete(client.id);
              }),
        ))
      ],
    );
  }

  @override
  int get rowCount => clients.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
