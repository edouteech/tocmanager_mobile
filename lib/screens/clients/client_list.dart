// ignore_for_file: unused_local_variable, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:tocmanager/models/Clients.dart';

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
    super.initState();
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
                          DataColumn(label: Center(child: Text("Date"))),
                          DataColumn(label: Center(child: Text("Name"))),
                          DataColumn(
                              label: Center(child: Text("Categorie parente"))),
                          DataColumn(label: Center(child: Text("Editer"))),
                          DataColumn(label: Center(child: Text("Effacer"))),
                        ],
                        source: DataTableRow(
                          data: clients,
                          // onDelete: _deleteCategory,
                          // onEdit: _showFormDialog,
                        ),
                      ),
                    ),
                  ),
          );
  }
}

class DataTableRow extends DataTableSource {
  final List<dynamic> data;
  // final Function(int?) onDelete;
  // final Function(int?, int?, String?) onEdit;
  DataTableRow(
      {required this.data});

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
                // onDelete(client.id);
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
