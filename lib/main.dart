import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const keyApplicationId = 'kItbjpqOahN63RsVt4zigbjLnOTUhklCbVrLC34k';
  const keyClientKey = 'gs6aqVr4Eau0Jn5w3nMLjSk6lDqyp9uGwmM4ufNH';
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, debug: true);

  runApp(const MyApp());
}

class CepObject extends ParseObject implements ParseCloneable {
  CepObject() : super(_keyTableName);

  CepObject.clone() : this();

  static const String _keyTableName = 'Cep';

  int get cep =>
      get<int>('cep') ?? 0; // Use 0 como valor padrão se o CEP estiver ausente
  set cep(int value) => set<int>('cep', value); // Agora é definido como String

  String get logradouro =>
      get<String>('logradouro') ??
      ''; // Use '?? ""' para garantir que seja sempre uma String não nula
  set logradouro(String value) => set<String>('logradouro', value);

  String get bairro =>
      get<String>('bairro') ??
      ''; // Use '?? ""' para garantir que seja sempre uma String não nula
  set bairro(String value) => set<String>('bairro', value);

  String get cidade =>
      get<String>('cidade') ??
      ''; // Use '?? ""' para garantir que seja sempre uma String não nula
  set cidade(String value) => set<String>('cidade', value);

  String get estado =>
      get<String>('estado') ??
      ''; // Use '?? ""' para garantir que seja sempre uma String não nula
  set estado(String value) => set<String>('estado', value);

  // Outros campos e métodos, se necessário
}

class CEP {
  final String cep;
  final String logradouro;
  final String bairro;
  final String cidade;
  final String estado;

  CEP(
      {required this.cep,
      required this.logradouro,
      required this.bairro,
      required this.cidade,
      required this.estado});
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CEPList(),
    );
  }
}

class CEPList extends StatefulWidget {
  const CEPList({Key? key}) : super(key: key);

  @override
  _CEPListState createState() => _CEPListState();
}

class _CEPListState extends State<CEPList> {
  List<CEP> ceps = [];
  final String viaCepBaseUrl = 'https://viacep.com.br/ws/';

  Future<CEP> fetchCEP(String cep) async {
    final response = await http.get(Uri.parse('$viaCepBaseUrl$cep/json'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return CEP(
        cep: data['cep'],
        logradouro: data['logradouro'],
        bairro: data['bairro'],
        cidade: data['localidade'],
        estado: data['uf'],
      );
    } else {
      throw Exception('Erro ao buscar CEP');
    }
  }

  void addCEP(String cep) async {
    final newCEP = await fetchCEP(cep);
    ceps.add(newCEP);

    // Aqui você deve adicionar o código para enviar o CEP para o Back4App
    await saveCEPToBack4App(
        newCEP); // Chame a função com await para aguardar a conclusão
    setState(() {});
  }

  void updateCEP(CEP existingCEP) async {
    // Aqui você deve adicionar o código para atualizar o CEP no Back4App
    updateCEPInBack4App(existingCEP);
    setState(() {});
  }

  void deleteCEP(CEP cep) async {
    ceps.remove(cep);

    // Aqui você deve adicionar o código para excluir o CEP do Back4App
    deleteCEPInBack4App(cep);

    setState(() {});
  }

  Future<void> saveCEPToBack4App(CEP cep) async {
    final CepObject cepObject = CepObject()
      ..set('cep', cep.cep)
      ..set('logradouro', cep.logradouro)
      ..set('bairro', cep.bairro)
      ..set('cidade', cep.cidade)
      ..set('estado', cep.estado);

    try {
      final response = await cepObject.save();
      if (response.success) {
        print('CEP salvo com sucesso no Back4App!');
      } else {
        print('Erro ao salvar o CEP no Back4App: ${response.error!.message}');
      }
    } catch (e) {
      print('Erro ao salvar o CEP no Back4App: $e');
    }
  }

  Future<void> updateCEPInBack4App(CEP cep) async {
    final query = QueryBuilder(CepObject())..whereEqualTo('cep', cep.cep);
    final response = await query.query();
    if (response.success) {
      final cepObject = response.results?.first as CepObject;
      cepObject
        ..set('logradouro', cep.logradouro)
        ..set('bairro', cep.bairro)
        ..set('cidade', cep.cidade)
        ..set('estado', cep.estado);

      final updatedResponse = await cepObject.save();
      if (updatedResponse.success) {
        print('CEP atualizado com sucesso no Back4App!');
      } else {
        print(
            'Erro ao atualizar o CEP no Back4App: ${updatedResponse.error!.message}');
      }
    } else {
      print(
          'Erro ao buscar o CEP no Back4App para atualização: ${response.error!.message}');
    }
  }

  Future<void> deleteCEPInBack4App(CEP cep) async {
    final query = QueryBuilder(CepObject())..whereEqualTo('cep', cep.cep);
    final response = await query.query();
    if (response.success) {
      if (response.results != null && response.results!.isNotEmpty) {
        final cepObject = CepObject();
        cepObject.objectId = response.results!.first.objectId;
        final deletedResponse = await cepObject.delete();
        if (deletedResponse.success) {
          print('CEP excluído com sucesso no Back4App!');
        } else {
          print(
              'Erro ao excluir o CEP no Back4App: ${deletedResponse.error!.message}');
        }
      } else {
        print('CEP não encontrado no Back4App para exclusão.');
      }
    } else {
      print(
          'Erro ao buscar o CEP no Back4App para exclusão: ${response.error!.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CEP List'),
      ),
      body: ListView.builder(
        itemCount: ceps.length,
        itemBuilder: (context, index) {
          final cep = ceps[index];
          return ListTile(
            title: Text(cep.cep),
            subtitle: Text(
                '${cep.logradouro}, ${cep.bairro}, ${cep.cidade}, ${cep.estado}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => deleteCEP(cep),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Consultar CEP'),
                content: TextField(
                  decoration: const InputDecoration(labelText: 'CEP'),
                  onSubmitted: (value) {
                    addCEP(value);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
