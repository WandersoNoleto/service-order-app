// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Ordens de Serviço';

  @override
  String get navHistory => 'Histórico';

  @override
  String get navSettings => 'Configurações';

  @override
  String get navCreate => 'Criar';

  @override
  String get navCreateSemantic => 'Criar ordem de serviço';

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get saving => 'Salvando…';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Excluir';

  @override
  String get discard => 'Descartar';

  @override
  String get restore => 'Restaurar';

  @override
  String get clear => 'Limpar';

  @override
  String get tryAgain => 'Tentar de novo';

  @override
  String couldNotComplete(String error) {
    return 'Não foi possível concluir: $error';
  }

  @override
  String get historySearchHint => 'Buscar por cliente ou nº da OS';

  @override
  String get historyNoResults => 'Nenhuma ordem de serviço encontrada';

  @override
  String get historyEmptyTitle => 'Nenhuma ordem de serviço emitida ainda';

  @override
  String get historyEmptyBody =>
      'Toque em \"Criar\" para emitir a primeira ordem de serviço.';

  @override
  String get orderNoNumber => 'Sem número';

  @override
  String get customerNotInformed => 'Cliente não informado';

  @override
  String get newOrderTitle => 'Nova ordem de serviço';

  @override
  String get editOrderTitle => 'Editar ordem de serviço';

  @override
  String get saveOrder => 'Salvar ordem de serviço';

  @override
  String get sectionOrder => 'Ordem de serviço';

  @override
  String get orderNumberField => 'Nº da ordem de serviço';

  @override
  String get sectionCustomer => 'Cliente';

  @override
  String get customer => 'Cliente';

  @override
  String get customerDocument => 'CPF/CNPJ';

  @override
  String get address => 'Endereço';

  @override
  String get city => 'Cidade';

  @override
  String get state => 'Estado';

  @override
  String get contact => 'Contato';

  @override
  String get zip => 'CEP';

  @override
  String get sectionServiceCall => 'Atendimento';

  @override
  String get invoice => 'N.F.';

  @override
  String get warranty => 'Garantia';

  @override
  String get calledAt => 'Chamado';

  @override
  String get scheduledFor => 'Marcado p/';

  @override
  String get scheduledTime => 'Horário';

  @override
  String get installedAt => 'Instalado em';

  @override
  String get sectionServicesPerformed => 'Serviços executados';

  @override
  String get description => 'Descrição';

  @override
  String get sectionParts => 'Peças';

  @override
  String get addPart => 'Adicionar peça';

  @override
  String partNumber(int number) {
    return 'Peça $number';
  }

  @override
  String get removePart => 'Remover peça';

  @override
  String get partName => 'Nome da peça';

  @override
  String get quantityShort => 'Quant.';

  @override
  String get invalidQuantity => 'Inválida';

  @override
  String get code => 'Código';

  @override
  String unitPriceField(String symbol) {
    return 'Valor unit. ($symbol)';
  }

  @override
  String lineTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String get sectionValues => 'Valores';

  @override
  String get partsTotal => 'Total peças';

  @override
  String laborField(String symbol) {
    return 'Serviço ($symbol)';
  }

  @override
  String get total => 'TOTAL';

  @override
  String get sectionNotes => 'Observações';

  @override
  String get notes => 'Observações';

  @override
  String get sectionConclusion => 'Conclusão';

  @override
  String get equipmentOkQuestion =>
      'O equipamento foi consertado e revisado, estando em perfeitas condições de funcionamento?';

  @override
  String get invalidAmount => 'Valor inválido';

  @override
  String get duplicateNumberTitle => 'Número já usado';

  @override
  String duplicateNumberMessage(String number) {
    return 'Já existe a ordem de serviço nº $number. Salvar mesmo assim?';
  }

  @override
  String duplicateNumberMessageWithCustomer(String number, String customer) {
    return 'Já existe a ordem de serviço nº $number, de $customer. Salvar mesmo assim?';
  }

  @override
  String get saveAnyway => 'Salvar mesmo assim';

  @override
  String get discardChangesTitle => 'Descartar alterações?';

  @override
  String get discardOrderMessage => 'O que você preencheu não foi salvo.';

  @override
  String get discardCompanyMessage => 'O que você alterou não foi salvo.';

  @override
  String get orderTitle => 'Ordem de serviço';

  @override
  String orderTitleWithNumber(String number) {
    return 'Ordem de serviço $number';
  }

  @override
  String get sendPdf => 'Enviar PDF';

  @override
  String get image => 'Imagem';

  @override
  String get print => 'Imprimir';

  @override
  String documentError(String error) {
    return 'Erro ao gerar o documento:\n$error';
  }

  @override
  String get deleteOrderTitle => 'Excluir esta ordem de serviço?';

  @override
  String get deleteOrderMessage =>
      'Ela será removida do histórico. Esta ação não pode ser desfeita.';

  @override
  String get companyCardTitle => 'Empresa';

  @override
  String get companyCardFooter =>
      'Estes dados aparecem no cabeçalho de todas as ordens de serviço.';

  @override
  String get rowName => 'Nome';

  @override
  String get rowDocument => 'CNPJ';

  @override
  String get rowPhone => 'Telefone';

  @override
  String get rowAddress => 'Endereço';

  @override
  String get rowCity => 'Cidade';

  @override
  String get rowResponsible => 'Responsável';

  @override
  String get notConfigured =>
      'App iniciado sem configuração de cliente. Rode com --dart-define-from-file=clients/<pasta>/config.json.';

  @override
  String get version => 'Versão';

  @override
  String versionLabel(String version) {
    return 'Versão $version';
  }

  @override
  String get checkForUpdates => 'Verificar atualizações';

  @override
  String get upToDate => 'Você já está na versão mais recente.';

  @override
  String get languageAndFormat => 'Idioma e formato';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Automático (do celular)';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get region => 'Formato regional';

  @override
  String get regionHint => 'Moeda, datas e horas';

  @override
  String get regionSystem => 'Automático (do celular)';

  @override
  String get regionBrazil => 'Brasil';

  @override
  String get regionUnitedStates => 'Estados Unidos';

  @override
  String get sampleCompanyName => 'Empresa Exemplo';

  @override
  String get sampleCompanyDocument => '00.000.000/0001-00';

  @override
  String get sampleCompanyPhone => '(00) 00000-0000';

  @override
  String get sampleCompanyAddress => 'Rua Exemplo, 100 - Centro';

  @override
  String get sampleCompanyCity => 'Cidade Exemplo';

  @override
  String get sampleCompanyState => 'UF';

  @override
  String get sampleResponsible => 'Fulano de Tal';

  @override
  String get companyFormTitle => 'Dados da empresa';

  @override
  String get restoreAllDefaults => 'Restaurar tudo para o padrão';

  @override
  String get restoreAllTitle => 'Restaurar tudo?';

  @override
  String get restoreAllMessage =>
      'Todos os dados e a logo voltam ao que veio configurado no app.';

  @override
  String get companyNameField => 'Nome da empresa';

  @override
  String get companyNameRequired => 'Informe o nome da empresa';

  @override
  String get companyDocumentField => 'CNPJ';

  @override
  String get phoneWhatsapp => 'Telefone / WhatsApp';

  @override
  String get stateShort => 'UF';

  @override
  String get responsible => 'Responsável';

  @override
  String defaultValue(String value) {
    return 'Padrão: $value';
  }

  @override
  String get emptyValue => '(vazio)';

  @override
  String get restoreDefault => 'Restaurar padrão';

  @override
  String get logo => 'Logo';

  @override
  String get noLogo => 'Nenhuma logo cadastrada';

  @override
  String get changeLogo => 'Trocar logo';

  @override
  String get removeLogo => 'Remover logo';

  @override
  String get useDefaultLogo => 'Usar logo padrão';

  @override
  String couldNotLoadImage(String error) {
    return 'Não foi possível carregar a imagem: $error';
  }

  @override
  String get newVersionTitle => 'Nova versão disponível';

  @override
  String newVersionMessage(String version) {
    return 'A versão v$version do aplicativo está disponível.\n\nToque em \"Atualizar\" para instalar as melhorias mais recentes.';
  }

  @override
  String get later => 'Depois';

  @override
  String get update => 'Atualizar';

  @override
  String get releaseNotes => 'Release notes';

  @override
  String get downloadingUpdate => 'Baixando atualização';

  @override
  String get starting => 'Iniciando…';

  @override
  String get updateOffline => 'Sem conexão com o servidor de atualizações.';

  @override
  String updateServerError(int code) {
    return 'O servidor de atualizações respondeu $code.';
  }

  @override
  String get installPermission =>
      'Permita que este app instale atualizações: Configurações do Android > Apps > este app > Instalar apps desconhecidos. Depois tente de novo.';

  @override
  String get installDownloadFailed =>
      'Falha ao baixar a atualização. Verifique a internet e tente de novo.';

  @override
  String get installCanceled => 'Atualização cancelada.';

  @override
  String get installAlreadyRunning => 'Uma atualização já está em andamento.';

  @override
  String installError(String detail) {
    return 'Erro ao instalar a atualização ($detail).';
  }

  @override
  String pdfDocumentTitle(String number) {
    return 'Ordem de Serviço $number';
  }

  @override
  String get pdfFilePrefix => 'OS';

  @override
  String get pdfCompanyDocument => 'CNPJ';

  @override
  String get pdfResponsible => 'Responsável';

  @override
  String pdfContinuation(String company) {
    return '$company · continuação';
  }

  @override
  String pdfContinuationWithNumber(String company, String number) {
    return '$company · OS $number · continuação';
  }

  @override
  String pdfPage(int page, int total) {
    return 'Página $page/$total';
  }

  @override
  String get pdfTechnicalAssistance => 'ASSISTÊNCIA TÉCNICA';

  @override
  String get pdfOrderNumber => 'ORDEM DE SERVIÇO N°:';

  @override
  String get pdfServicesPerformed => 'Serviços Executados';

  @override
  String get pdfPartName => 'NOME DA PEÇA';

  @override
  String get pdfUnitPrice => 'Valor Unitário';

  @override
  String get pdfLineTotal => 'Valor Total';

  @override
  String get pdfPartsTotal => 'TOTAL PÇ';

  @override
  String get pdfLabor => 'SERVIÇO';

  @override
  String get pdfSignatureApproval => 'VISTO';

  @override
  String get pdfSignatureDate => 'DATA';

  @override
  String get pdfSignatureTechnician => 'TÉCNICO';

  @override
  String get pdfSignatureCustomer => 'CLIENTE';

  @override
  String get pdfEquipmentOk =>
      'O equipamento foi consertado e revisado, estando em perfeitas condições de funcionamento';
}
