import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

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
      debugShowCheckedModeBanner: false,
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
          actions: [
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                // Adicione a ação desejada para o ícone de configuração
              },
            ),
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                // Adicione a ação desejada para o ícone de notificação
              },
            ),
          ],
          title: Text('App Deputados'),
        ),
        body: TabBarView(
          children: [
            DeputadosPage(),
            ComissoesPage(),
          ],
        ),
        bottomNavigationBar: Container(
          color: Colors.green,
          child: TabBar(
            tabs: [
              Tab(text: 'Deputados'),
              Tab(text: 'Comissões'),
            ],
          ),
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
  List<dynamic>? comissoes;

  @override
  void initState() {
    super.initState();
    _carregarComissoes();
  }

  void _carregarComissoes() async {
    try {
      var url = 'https://dadosabertos.camara.leg.br/api/v2/orgaos';
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        var orgaos = data['dados'];

        setState(() {
          comissoes = orgaos.map((orgao) {
            return {
              'id': orgao['id'],
              'sigla': orgao['sigla'],
              'nome': orgao['nome'],
              'apelido': orgao['apelido'],
              'codTipoOrgao': orgao['codTipoOrgao'],
              'tipoOrgao': orgao['tipoOrgao'],
              'nomePublicacao': orgao['nomePublicacao'],
              'nomeResumido': orgao['nomeResumido'],
            };
          }).toList();
        });
      } else {
        print(
            'Erro ao obter comissões. Código de status: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao obter comissões: $e');
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Comissões'),
      ),
      body: comissoes != null
          ? (comissoes!.isEmpty
              ? Center(
                  child: Text('Nenhuma comissão encontrada'),
                )
              : ListView.builder(
                  itemCount: comissoes!.length,
                  itemBuilder: (context, index) {
                    var comissao = comissoes![index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalhesComissaoPage(
                              comissaoId: comissao['id']
                                  .toString(), // Converta para String
                              comissao: comissao,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(comissao['apelido']),
                            subtitle: Text(comissao['sigla']),
                          ),
                        ],
                      ),
                    );
                  },
                ))
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}

Future<List<dynamic>> obterMembrosComissao(String comissaoId) async {
  final url =
      'https://dadosabertos.camara.leg.br/api/v2/orgaos/$comissaoId/membros';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final membros = data['dados'] as List<dynamic>;
    return membros;
  } else {
    throw Exception('Falha ao carregar os membros da comissão');
  }
}

class DetalhesComissaoPage extends StatelessWidget {
  final String comissaoId;
  final dynamic comissao;

  DetalhesComissaoPage({required this.comissaoId, required this.comissao});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes da Comissão'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              comissao['apelido'],
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Sigla: ${comissao['sigla']}',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'Id: ${comissao['id']}',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 16),
            Text(
              'Membros da Comissão:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: obterMembrosComissao(comissaoId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text('Erro ao carregar os membros da comissão'));
                  } else {
                    final membros = snapshot.data;
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: membros!.length,
                      itemBuilder: (context, index) {
                        var membro = membros[index];
                        return GestureDetector(
                          onTap: () {
                            _exibirDetalhesMembro(context, membro);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage:
                                      NetworkImage(membro['urlFoto'] ?? ''),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  membro['nome'] ?? '',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  membro['siglaPartido'] ?? '',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _exibirDetalhesMembro(BuildContext context, dynamic membro) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(membro['nome'] ?? ''),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Cargo: ${membro['cargo'] ?? ''}'),
              // Adicione mais informações do membro aqui, se necessário
            ],
          ),
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
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.picture_as_pdf),
          ),
        ],
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
            SizedBox(height: 8.0),
            Text(
              'ID: ${deputado['id']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
            Text(
              deputado['nome'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
            SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Estado: ${deputado['siglaUf']}'),
                Text('Partido: ${deputado['siglaPartido']}'),
                Text('Sexo: ${deputado['siglaSexo']}'),
              ],
            ),
            Text('E-mail: ${deputado['email']}'),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                var response = await http.get(Uri.parse(
                    'https://dadosabertos.camara.leg.br/api/v2/deputados/${widget.deputadoId}/eventos?itens=5'));

                if (response.statusCode == 200) {
                  var data = jsonDecode(response.body);
                  var eventos = data['dados'];

                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          'Atividades de: ${deputado['nome']}',
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            children: eventos.map<Widget>((evento) {
                              var descricaoEvento = evento['descricao'];
                              var dataEvento = evento['dataHoraInicio'];
                              var formatoData = DateFormat('dd/MM/yyyy HH:mm');
                              var dataFormatada = formatoData
                                  .format(DateTime.parse(dataEvento));

                              var urlRegistro = evento['urlRegistro'];
                              var uri = Uri.parse(urlRegistro);
                              var dominio = uri.host;

                              return Column(
                                children: [
                                  Text(
                                    descricaoEvento,
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Data: $dataFormatada',
                                      style: TextStyle(
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: GestureDetector(
                                      onTap: () async {
                                        if (await canLaunch(urlRegistro)) {
                                          await launch(urlRegistro);
                                        }
                                      },
                                      child: Text(
                                        'Assistir: $dominio',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Divider(),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
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
                } else {
                  print('Falha ao carregar o histórico do deputado');
                }
              },
              child: Text('Atividades'),
            ),
            Divider(),
            Text(
              'Despesas de: ${deputado['nome']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
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
