import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Nova lista de deputados

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomePage(),
      routes: {
        '/deputados': (context) => DeputadosPage(),
        '/comissoes': (context) => ComissoesPage(),
        '/detalhes': (context) {
          final Map<String, dynamic> arguments = ModalRoute.of(context)!
              .settings
              .arguments as Map<String, dynamic>;
          final int deputadoId = arguments['deputadoId'] as int;
          final List<dynamic> deputados =
              arguments['deputados'] as List<dynamic>;
          return DetalhesPage(deputadoId: deputadoId, deputados: deputados);
        },
      },
    );
  }
}

class ServicoAPI {
  static Future<dynamic> obterDeputados() async {
    var url = Uri.parse('https://dadosabertos.camara.leg.br/api/v2/deputados');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao obter deputados');
    }
  }

  static Future<dynamic> obterDespesasDeputado(int deputadoId) async {
    var url = Uri.parse(
        'https://dadosabertos.camara.leg.br/api/v2/deputados/$deputadoId/despesas');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao obter despesas do deputado');
    }
  }

  static Future<dynamic> obterComissoes() async {
    var url = Uri.parse('https://dadosabertos.camara.leg.br/api/v2/comissoes');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao obter comissões');
    }
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('App Deputados'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Deputados'),
              Tab(text: 'Comissões'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            DeputadosPage(),
            ComissoesPage(),
          ],
        ),
      ),
    );
  }
}

class DeputadosPage extends StatefulWidget {
  @override
  _DeputadosPageState createState() => _DeputadosPageState();
}

class _DeputadosPageState extends State<DeputadosPage> {
  List<dynamic> deputados = [];
  List<dynamic> deputadosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _carregarDeputados();
  }

  void _carregarDeputados() async {
    try {
      var response = await ServicoAPI.obterDeputados();
      setState(() {
        deputados = response['dados'] ?? [];
        deputadosFiltrados = deputados;
      });
    } catch (e) {
      print('Erro ao obter deputados: $e');
    }
  }

  void _verDetalhesDeputado(dynamic deputado) {
    int deputadoId = deputado['id']; // Obtém o ID do deputado
    Navigator.pushNamed(context, '/detalhes', arguments: {
      'deputadoId': deputadoId,
      'deputados': deputados,
    });
  }

  void _filtrarDeputados(String query) {
    setState(() {
      deputadosFiltrados = deputados.where((deputado) {
        final String nome = deputado['nome'].toString().toLowerCase();
        final String partido =
            deputado['siglaPartido'].toString().toLowerCase();
        final String estado = deputado['siglaUf'].toString().toLowerCase();
        final String lowercaseQuery = query.toLowerCase();

        return nome.contains(lowercaseQuery) ||
            partido.contains(lowercaseQuery) ||
            estado.contains(lowercaseQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              onChanged: _filtrarDeputados,
              decoration: InputDecoration(
                labelText: 'Pesquisar',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: deputadosFiltrados.length,
              itemBuilder: (context, index) {
                var deputado = deputadosFiltrados[index];
                String imageUrl = deputado['urlFoto'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(imageUrl),
                  ),
                  title: Text(deputado['nome']),
                  subtitle: Text(
                      '${deputado['siglaPartido']} - ${deputado['siglaUf']}'),
                  onTap: () => _verDetalhesDeputado(deputado),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ComissoesPage extends StatefulWidget {
  @override
  _ComissoesPageState createState() => _ComissoesPageState();
}

class _ComissoesPageState extends State<ComissoesPage> {
  List<dynamic> comissoes = [];

  @override
  void initState() {
    super.initState();
    _carregarComissoes();
  }

  void _carregarComissoes() async {
    try {
      var response = await ServicoAPI.obterComissoes();
      setState(() {
        comissoes = response['dados'] ?? [];
      });
    } catch (e) {
      print('Erro ao obter comissões: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: comissoes.length,
        itemBuilder: (context, index) {
          var comissao = comissoes[index];
          return ListTile(
            title: Text(comissao['nome']),
            subtitle: Text(comissao['sigla']),
          );
        },
      ),
    );
  }
}

class DetalhesPage extends StatefulWidget {
  final int deputadoId;
  final List<dynamic> deputados;

  DetalhesPage({required this.deputadoId, required this.deputados});

  @override
  _DetalhesPageState createState() => _DetalhesPageState();
}

class _DetalhesPageState extends State<DetalhesPage> {
  String? imageUrl; // URL da imagem do deputado
  List<dynamic> despesas = []; // Nova lista de despesas
  int? selectedAno; // Ano selecionado
  int? selectedMes; // Mês selecionado

  @override
  void initState() {
    super.initState();
    _carregarDetalhesDeputado();
    _carregarDespesasDeputado();
  }

  void _carregarDetalhesDeputado() async {
    var deputado = widget.deputados.firstWhere(
      (dep) => dep['id'] == widget.deputadoId,
      orElse: () => {},
    );

    // Obtém a URL da imagem do deputado
    String fotoUrl = deputado['urlFoto'];

    // Carrega a imagem do deputado
    var response = await http.get(Uri.parse(fotoUrl));
    if (response.statusCode == 200) {
      setState(() {
        imageUrl = fotoUrl;
      });
    } else {
      print('Falha ao carregar a imagem do deputado');
    }
  }

  void _carregarDespesasDeputado() async {
    try {
      var response = await ServicoAPI.obterDespesasDeputado(widget.deputadoId);

      setState(() {
        despesas = response['dados'] ?? [];
      });
    } catch (e) {
      print('Erro ao obter despesas do deputado: $e');
    }
  }

  void _filtrarDespesas(int? ano, int? mes) {
    setState(() {
      final deputado = widget.deputados.firstWhere(
        (dep) => dep['id'] == widget.deputadoId,
        orElse: () => null,
      );

      if (deputado != null) {
        final dynamic despesasDeputado = deputado['despesas'];

        if (despesasDeputado != null) {
          if (ano != null && mes != null) {
            despesas = despesasDeputado.where((despesa) {
              final String dataDocumento = despesa['dataDocumento'];
              final DateTime dateTime = DateTime.parse(dataDocumento);

              return dateTime.year == ano && dateTime.month == mes;
            }).toList();
          } else {
            despesas = List.from(despesasDeputado);
          }
        } else {
          despesas = [];
        }
      } else {
        despesas = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    var deputado = widget.deputados.firstWhere(
      (dep) => dep['id'] == widget.deputadoId,
      orElse: () => {},
    );
    final List<int> anos = [2022, 2023, 2024]; // Lista de anos disponíveis
    final List<int> meses = [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12
    ]; // Lista de meses disponíveis

    return Scaffold(
      appBar: AppBar(
        title: Text(deputado['nome']),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            imageUrl != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(imageUrl!),
                    radius: 50.0,
                  )
                : Container(),
            SizedBox(height: 16.0),
            Text(
              'ID: ${deputado['id']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            Text(
              deputado['nome'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24.0,
              ),
            ),
            SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('Estado: ${deputado['siglaUf']}'),
                Text('Partido: ${deputado['siglaPartido']}'),
                Text('Sexo: ${deputado['sexo']}'),
              ],
            ),
            Text('E-mail: ${deputado['email']}'),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Janela Modal'),
                      content: Text('Este é um exemplo de janela modal.'),
                      actions: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Fechar'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Atividades'),
            ),
            SizedBox(height: 10.0),
            Text(
              'Despesas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            SizedBox(height: 0.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                DropdownButton<int>(
                  hint: Text('Ano'),
                  value: selectedAno,
                  onChanged: (value) {
                    setState(() {
                      selectedAno = value;
                      _filtrarDespesas(selectedAno, selectedMes);
                    });
                  },
                  items: anos.map((ano) {
                    return DropdownMenuItem<int>(
                      value: ano,
                      child: Text(ano.toString()),
                    );
                  }).toList(),
                ),
                SizedBox(width: 16.0),
                DropdownButton<int>(
                  hint: Text('Mês'),
                  value: selectedMes,
                  onChanged: (value) {
                    setState(() {
                      selectedMes = value;
                      _filtrarDespesas(selectedAno, selectedMes);
                    });
                  },
                  items: meses.map((mes) {
                    return DropdownMenuItem<int>(
                      value: mes,
                      child: Text(mes.toString()),
                    );
                  }).toList(),
                ),
                SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: () {
                    // Lógica para filtrar as despesas
                    _filtrarDespesas(selectedAno, selectedMes);
                  },
                  child: Text('Filtrar'),
                ),
              ],
            ),
            Text(
              'Filtro: ${selectedAno ?? 'Todos os anos'} - ${selectedMes ?? 'Todos os meses'}',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 10.0,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: despesas.length,
                itemBuilder: (context, index) {
                  final despesa = despesas[index];
                  return ListTile(
                    title: RichText(
                      text: TextSpan(
                        text: 'Descrição: ',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black),
                        children: [
                          TextSpan(
                            text: despesa['tipoDespesa'],
                          ),
                        ],
                      ),
                    ),
                    subtitle: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Valor: R\$ ${despesa['valorDocumento']}',
                        ),
                        Text(
                          despesa['dataDocumento'],
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
