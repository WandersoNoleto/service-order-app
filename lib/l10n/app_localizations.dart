import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ordens de Serviço'**
  String get appTitle;

  /// No description provided for @navHistory.
  ///
  /// In pt, this message translates to:
  /// **'Ordens'**
  String get navHistory;

  /// No description provided for @navSettings.
  ///
  /// In pt, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

  /// No description provided for @navCreate.
  ///
  /// In pt, this message translates to:
  /// **'Nova ordem'**
  String get navCreate;

  /// No description provided for @navCreateSemantic.
  ///
  /// In pt, this message translates to:
  /// **'Criar ordem de serviço'**
  String get navCreateSemantic;

  /// No description provided for @today.
  ///
  /// In pt, this message translates to:
  /// **'Hoje'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In pt, this message translates to:
  /// **'Ontem'**
  String get yesterday;

  /// No description provided for @yes.
  ///
  /// In pt, this message translates to:
  /// **'Sim'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In pt, this message translates to:
  /// **'Não'**
  String get no;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In pt, this message translates to:
  /// **'Salvando…'**
  String get saving;

  /// No description provided for @edit.
  ///
  /// In pt, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @automatic.
  ///
  /// In pt, this message translates to:
  /// **'Automático'**
  String get automatic;

  /// No description provided for @draftNotSaved.
  ///
  /// In pt, this message translates to:
  /// **'Rascunho não salvo'**
  String get draftNotSaved;

  /// No description provided for @orderTotal.
  ///
  /// In pt, this message translates to:
  /// **'Total'**
  String get orderTotal;

  /// No description provided for @itemsCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhum item} =1{1 item} other{{count} itens}}'**
  String itemsCount(int count);

  /// No description provided for @delete.
  ///
  /// In pt, this message translates to:
  /// **'Excluir'**
  String get delete;

  /// No description provided for @discard.
  ///
  /// In pt, this message translates to:
  /// **'Descartar'**
  String get discard;

  /// No description provided for @restore.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar'**
  String get restore;

  /// No description provided for @clear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get clear;

  /// No description provided for @tryAgain.
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get tryAgain;

  /// No description provided for @couldNotComplete.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível concluir: {error}'**
  String couldNotComplete(String error);

  /// No description provided for @historySearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Cliente, número ou serviço'**
  String get historySearchHint;

  /// No description provided for @historyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ordens de serviço'**
  String get historyTitle;

  /// No description provided for @filterAll.
  ///
  /// In pt, this message translates to:
  /// **'Todas'**
  String get filterAll;

  /// No description provided for @filterLast7Days.
  ///
  /// In pt, this message translates to:
  /// **'7 dias'**
  String get filterLast7Days;

  /// No description provided for @filterThisMonth.
  ///
  /// In pt, this message translates to:
  /// **'Este mês'**
  String get filterThisMonth;

  /// No description provided for @ordersCount.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhuma ordem} =1{1 ordem} other{{count} ordens}}'**
  String ordersCount(int count);

  /// No description provided for @orderNumberShort.
  ///
  /// In pt, this message translates to:
  /// **'Nº {number}'**
  String orderNumberShort(String number);

  /// No description provided for @historyNoResults.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma ordem de serviço encontrada'**
  String get historyNoResults;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma ordem de serviço emitida ainda'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In pt, this message translates to:
  /// **'Toque em \"Nova ordem\" para emitir a primeira ordem de serviço.'**
  String get historyEmptyBody;

  /// No description provided for @orderNoNumber.
  ///
  /// In pt, this message translates to:
  /// **'Sem número'**
  String get orderNoNumber;

  /// No description provided for @customerNotInformed.
  ///
  /// In pt, this message translates to:
  /// **'Cliente não informado'**
  String get customerNotInformed;

  /// No description provided for @newOrderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova ordem'**
  String get newOrderTitle;

  /// No description provided for @editOrderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Editar ordem'**
  String get editOrderTitle;

  /// No description provided for @saveOrder.
  ///
  /// In pt, this message translates to:
  /// **'Revisar e gerar PDF'**
  String get saveOrder;

  /// No description provided for @sectionOrder.
  ///
  /// In pt, this message translates to:
  /// **'Ordem de serviço'**
  String get sectionOrder;

  /// No description provided for @orderNumberField.
  ///
  /// In pt, this message translates to:
  /// **'Nº da ordem de serviço'**
  String get orderNumberField;

  /// No description provided for @sectionCustomer.
  ///
  /// In pt, this message translates to:
  /// **'Cliente'**
  String get sectionCustomer;

  /// No description provided for @customer.
  ///
  /// In pt, this message translates to:
  /// **'Cliente'**
  String get customer;

  /// No description provided for @customerDocument.
  ///
  /// In pt, this message translates to:
  /// **'CPF/CNPJ'**
  String get customerDocument;

  /// No description provided for @address.
  ///
  /// In pt, this message translates to:
  /// **'Endereço'**
  String get address;

  /// No description provided for @city.
  ///
  /// In pt, this message translates to:
  /// **'Cidade'**
  String get city;

  /// No description provided for @state.
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get state;

  /// No description provided for @contact.
  ///
  /// In pt, this message translates to:
  /// **'Contato'**
  String get contact;

  /// No description provided for @zip.
  ///
  /// In pt, this message translates to:
  /// **'CEP'**
  String get zip;

  /// No description provided for @sectionServiceCall.
  ///
  /// In pt, this message translates to:
  /// **'Atendimento'**
  String get sectionServiceCall;

  /// No description provided for @invoice.
  ///
  /// In pt, this message translates to:
  /// **'N.F.'**
  String get invoice;

  /// No description provided for @warranty.
  ///
  /// In pt, this message translates to:
  /// **'Garantia'**
  String get warranty;

  /// No description provided for @calledAt.
  ///
  /// In pt, this message translates to:
  /// **'Chamado'**
  String get calledAt;

  /// No description provided for @scheduledFor.
  ///
  /// In pt, this message translates to:
  /// **'Marcado p/'**
  String get scheduledFor;

  /// No description provided for @scheduledTime.
  ///
  /// In pt, this message translates to:
  /// **'Horário'**
  String get scheduledTime;

  /// No description provided for @installedAt.
  ///
  /// In pt, this message translates to:
  /// **'Instalado em'**
  String get installedAt;

  /// No description provided for @sectionServicesPerformed.
  ///
  /// In pt, this message translates to:
  /// **'Serviços executados'**
  String get sectionServicesPerformed;

  /// No description provided for @description.
  ///
  /// In pt, this message translates to:
  /// **'Descrição'**
  String get description;

  /// No description provided for @partsAndMaterials.
  ///
  /// In pt, this message translates to:
  /// **'Peças e materiais'**
  String get partsAndMaterials;

  /// No description provided for @decreaseQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Diminuir quantidade'**
  String get decreaseQuantity;

  /// No description provided for @increaseQuantity.
  ///
  /// In pt, this message translates to:
  /// **'Aumentar quantidade'**
  String get increaseQuantity;

  /// No description provided for @totalsBreakdown.
  ///
  /// In pt, this message translates to:
  /// **'Peças {parts} · Mão de obra {labor}'**
  String totalsBreakdown(String parts, String labor);

  /// No description provided for @addPart.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar peça'**
  String get addPart;

  /// No description provided for @removePart.
  ///
  /// In pt, this message translates to:
  /// **'Remover peça'**
  String get removePart;

  /// No description provided for @partName.
  ///
  /// In pt, this message translates to:
  /// **'Nome da peça'**
  String get partName;

  /// No description provided for @quantityShort.
  ///
  /// In pt, this message translates to:
  /// **'Quant.'**
  String get quantityShort;

  /// No description provided for @code.
  ///
  /// In pt, this message translates to:
  /// **'Código'**
  String get code;

  /// No description provided for @unitPriceField.
  ///
  /// In pt, this message translates to:
  /// **'Valor unit. ({symbol})'**
  String unitPriceField(String symbol);

  /// No description provided for @laborField.
  ///
  /// In pt, this message translates to:
  /// **'Mão de obra ({symbol})'**
  String laborField(String symbol);

  /// No description provided for @total.
  ///
  /// In pt, this message translates to:
  /// **'TOTAL'**
  String get total;

  /// No description provided for @notes.
  ///
  /// In pt, this message translates to:
  /// **'Observações'**
  String get notes;

  /// No description provided for @equipmentOkQuestion.
  ///
  /// In pt, this message translates to:
  /// **'O equipamento foi consertado e revisado, estando em perfeitas condições de funcionamento?'**
  String get equipmentOkQuestion;

  /// No description provided for @invalidAmount.
  ///
  /// In pt, this message translates to:
  /// **'Valor inválido'**
  String get invalidAmount;

  /// No description provided for @duplicateNumberTitle.
  ///
  /// In pt, this message translates to:
  /// **'Número já usado'**
  String get duplicateNumberTitle;

  /// No description provided for @duplicateNumberMessage.
  ///
  /// In pt, this message translates to:
  /// **'Já existe a ordem de serviço nº {number}. Salvar mesmo assim?'**
  String duplicateNumberMessage(String number);

  /// No description provided for @duplicateNumberMessageWithCustomer.
  ///
  /// In pt, this message translates to:
  /// **'Já existe a ordem de serviço nº {number}, de {customer}. Salvar mesmo assim?'**
  String duplicateNumberMessageWithCustomer(String number, String customer);

  /// No description provided for @saveAnyway.
  ///
  /// In pt, this message translates to:
  /// **'Salvar mesmo assim'**
  String get saveAnyway;

  /// No description provided for @discardChangesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Descartar alterações?'**
  String get discardChangesTitle;

  /// No description provided for @discardOrderMessage.
  ///
  /// In pt, this message translates to:
  /// **'O que você preencheu não foi salvo.'**
  String get discardOrderMessage;

  /// No description provided for @discardCompanyMessage.
  ///
  /// In pt, this message translates to:
  /// **'O que você alterou não foi salvo.'**
  String get discardCompanyMessage;

  /// No description provided for @orderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ordem de serviço'**
  String get orderTitle;

  /// No description provided for @orderTitleWithNumber.
  ///
  /// In pt, this message translates to:
  /// **'Ordem de serviço {number}'**
  String orderTitleWithNumber(String number);

  /// No description provided for @sendPdf.
  ///
  /// In pt, this message translates to:
  /// **'Enviar PDF'**
  String get sendPdf;

  /// No description provided for @image.
  ///
  /// In pt, this message translates to:
  /// **'Imagem'**
  String get image;

  /// No description provided for @print.
  ///
  /// In pt, this message translates to:
  /// **'Imprimir'**
  String get print;

  /// No description provided for @documentError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao gerar o documento:\n{error}'**
  String documentError(String error);

  /// No description provided for @deleteOrderTitle.
  ///
  /// In pt, this message translates to:
  /// **'Excluir esta ordem de serviço?'**
  String get deleteOrderTitle;

  /// No description provided for @deleteOrderMessage.
  ///
  /// In pt, this message translates to:
  /// **'Ela será removida do histórico. Esta ação não pode ser desfeita.'**
  String get deleteOrderMessage;

  /// No description provided for @companyCardFooter.
  ///
  /// In pt, this message translates to:
  /// **'Estes dados aparecem no cabeçalho do PDF'**
  String get companyCardFooter;

  /// No description provided for @viewTemplate.
  ///
  /// In pt, this message translates to:
  /// **'Ver modelo'**
  String get viewTemplate;

  /// No description provided for @settingsPreferences.
  ///
  /// In pt, this message translates to:
  /// **'Preferências'**
  String get settingsPreferences;

  /// No description provided for @settingsData.
  ///
  /// In pt, this message translates to:
  /// **'Dados'**
  String get settingsData;

  /// No description provided for @settingsApp.
  ///
  /// In pt, this message translates to:
  /// **'Aplicativo'**
  String get settingsApp;

  /// No description provided for @backup.
  ///
  /// In pt, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @backupNever.
  ///
  /// In pt, this message translates to:
  /// **'Último: nunca'**
  String get backupNever;

  /// No description provided for @recommended.
  ///
  /// In pt, this message translates to:
  /// **'Recomendado'**
  String get recommended;

  /// No description provided for @pdfFolder.
  ///
  /// In pt, this message translates to:
  /// **'Pasta dos PDFs'**
  String get pdfFolder;

  /// No description provided for @updates.
  ///
  /// In pt, this message translates to:
  /// **'Atualizações'**
  String get updates;

  /// No description provided for @checkNow.
  ///
  /// In pt, this message translates to:
  /// **'Verificar'**
  String get checkNow;

  /// No description provided for @comingSoon.
  ///
  /// In pt, this message translates to:
  /// **'Funcionalidade em desenvolvimento. Aguarde!'**
  String get comingSoon;

  /// No description provided for @notConfigured.
  ///
  /// In pt, this message translates to:
  /// **'App iniciado sem configuração de cliente. Rode com --dart-define-from-file=clients/<pasta>/config.json.'**
  String get notConfigured;

  /// No description provided for @version.
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get version;

  /// No description provided for @versionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Versão {version}'**
  String versionLabel(String version);

  /// No description provided for @upToDate.
  ///
  /// In pt, this message translates to:
  /// **'Você já está na versão mais recente.'**
  String get upToDate;

  /// No description provided for @language.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In pt, this message translates to:
  /// **'Automático (do celular)'**
  String get languageSystem;

  /// No description provided for @languagePortuguese.
  ///
  /// In pt, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// No description provided for @languageEnglish.
  ///
  /// In pt, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @region.
  ///
  /// In pt, this message translates to:
  /// **'Formato regional'**
  String get region;

  /// No description provided for @regionSystem.
  ///
  /// In pt, this message translates to:
  /// **'Automático (do celular)'**
  String get regionSystem;

  /// No description provided for @regionBrazil.
  ///
  /// In pt, this message translates to:
  /// **'Brasil'**
  String get regionBrazil;

  /// No description provided for @regionUnitedStates.
  ///
  /// In pt, this message translates to:
  /// **'Estados Unidos'**
  String get regionUnitedStates;

  /// No description provided for @theme.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In pt, this message translates to:
  /// **'Automático (do celular)'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get themeDark;

  /// No description provided for @sampleCompanyName.
  ///
  /// In pt, this message translates to:
  /// **'Empresa Exemplo'**
  String get sampleCompanyName;

  /// No description provided for @sampleCompanyDocument.
  ///
  /// In pt, this message translates to:
  /// **'00.000.000/0001-00'**
  String get sampleCompanyDocument;

  /// No description provided for @sampleCompanyPhone.
  ///
  /// In pt, this message translates to:
  /// **'(00) 00000-0000'**
  String get sampleCompanyPhone;

  /// No description provided for @sampleCompanyAddress.
  ///
  /// In pt, this message translates to:
  /// **'Rua Exemplo, 100 - Centro'**
  String get sampleCompanyAddress;

  /// No description provided for @sampleCompanyCity.
  ///
  /// In pt, this message translates to:
  /// **'Cidade Exemplo'**
  String get sampleCompanyCity;

  /// No description provided for @sampleCompanyState.
  ///
  /// In pt, this message translates to:
  /// **'UF'**
  String get sampleCompanyState;

  /// No description provided for @sampleResponsible.
  ///
  /// In pt, this message translates to:
  /// **'Fulano de Tal'**
  String get sampleResponsible;

  /// No description provided for @companyFormTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dados da empresa'**
  String get companyFormTitle;

  /// No description provided for @restoreAllDefaults.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar tudo para o padrão'**
  String get restoreAllDefaults;

  /// No description provided for @restoreAllTitle.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar tudo?'**
  String get restoreAllTitle;

  /// No description provided for @restoreAllMessage.
  ///
  /// In pt, this message translates to:
  /// **'Todos os dados e a logo voltam ao que veio configurado no app.'**
  String get restoreAllMessage;

  /// No description provided for @companyNameField.
  ///
  /// In pt, this message translates to:
  /// **'Nome da empresa'**
  String get companyNameField;

  /// No description provided for @companyNameRequired.
  ///
  /// In pt, this message translates to:
  /// **'Informe o nome da empresa'**
  String get companyNameRequired;

  /// No description provided for @companyDocumentField.
  ///
  /// In pt, this message translates to:
  /// **'CNPJ'**
  String get companyDocumentField;

  /// No description provided for @phoneWhatsapp.
  ///
  /// In pt, this message translates to:
  /// **'Telefone / WhatsApp'**
  String get phoneWhatsapp;

  /// No description provided for @stateShort.
  ///
  /// In pt, this message translates to:
  /// **'UF'**
  String get stateShort;

  /// No description provided for @responsible.
  ///
  /// In pt, this message translates to:
  /// **'Responsável'**
  String get responsible;

  /// No description provided for @defaultValue.
  ///
  /// In pt, this message translates to:
  /// **'Padrão: {value}'**
  String defaultValue(String value);

  /// No description provided for @restoreDefault.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar padrão'**
  String get restoreDefault;

  /// No description provided for @logo.
  ///
  /// In pt, this message translates to:
  /// **'Logo'**
  String get logo;

  /// No description provided for @noLogo.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma logo cadastrada'**
  String get noLogo;

  /// No description provided for @changeLogo.
  ///
  /// In pt, this message translates to:
  /// **'Trocar logo'**
  String get changeLogo;

  /// No description provided for @removeLogo.
  ///
  /// In pt, this message translates to:
  /// **'Remover logo'**
  String get removeLogo;

  /// No description provided for @useDefaultLogo.
  ///
  /// In pt, this message translates to:
  /// **'Usar logo padrão'**
  String get useDefaultLogo;

  /// No description provided for @couldNotLoadImage.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar a imagem: {error}'**
  String couldNotLoadImage(String error);

  /// No description provided for @newVersionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nova versão disponível'**
  String get newVersionTitle;

  /// No description provided for @newVersionMessage.
  ///
  /// In pt, this message translates to:
  /// **'A versão v{version} do aplicativo está disponível.\n\nToque em \"Atualizar\" para instalar as melhorias mais recentes.'**
  String newVersionMessage(String version);

  /// No description provided for @later.
  ///
  /// In pt, this message translates to:
  /// **'Depois'**
  String get later;

  /// No description provided for @update.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get update;

  /// No description provided for @releaseNotes.
  ///
  /// In pt, this message translates to:
  /// **'Release notes'**
  String get releaseNotes;

  /// No description provided for @downloadingUpdate.
  ///
  /// In pt, this message translates to:
  /// **'Baixando atualização'**
  String get downloadingUpdate;

  /// No description provided for @starting.
  ///
  /// In pt, this message translates to:
  /// **'Iniciando…'**
  String get starting;

  /// No description provided for @updateOffline.
  ///
  /// In pt, this message translates to:
  /// **'Sem conexão com o servidor de atualizações.'**
  String get updateOffline;

  /// No description provided for @updateServerError.
  ///
  /// In pt, this message translates to:
  /// **'O servidor de atualizações respondeu {code}.'**
  String updateServerError(int code);

  /// No description provided for @installPermission.
  ///
  /// In pt, this message translates to:
  /// **'Permita que este app instale atualizações: Configurações do Android > Apps > este app > Instalar apps desconhecidos. Depois tente de novo.'**
  String get installPermission;

  /// No description provided for @installDownloadFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falha ao baixar a atualização. Verifique a internet e tente de novo.'**
  String get installDownloadFailed;

  /// No description provided for @installCanceled.
  ///
  /// In pt, this message translates to:
  /// **'Atualização cancelada.'**
  String get installCanceled;

  /// No description provided for @installAlreadyRunning.
  ///
  /// In pt, this message translates to:
  /// **'Uma atualização já está em andamento.'**
  String get installAlreadyRunning;

  /// No description provided for @installError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao instalar a atualização ({detail}).'**
  String installError(String detail);

  /// No description provided for @pdfDocumentTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ordem de Serviço {number}'**
  String pdfDocumentTitle(String number);

  /// No description provided for @pdfFilePrefix.
  ///
  /// In pt, this message translates to:
  /// **'OS'**
  String get pdfFilePrefix;

  /// No description provided for @pdfCompanyDocument.
  ///
  /// In pt, this message translates to:
  /// **'CNPJ'**
  String get pdfCompanyDocument;

  /// No description provided for @pdfResponsible.
  ///
  /// In pt, this message translates to:
  /// **'Responsável'**
  String get pdfResponsible;

  /// No description provided for @pdfContinuation.
  ///
  /// In pt, this message translates to:
  /// **'{company} · continuação'**
  String pdfContinuation(String company);

  /// No description provided for @pdfContinuationWithNumber.
  ///
  /// In pt, this message translates to:
  /// **'{company} · OS {number} · continuação'**
  String pdfContinuationWithNumber(String company, String number);

  /// No description provided for @pdfPage.
  ///
  /// In pt, this message translates to:
  /// **'Página {page}/{total}'**
  String pdfPage(int page, int total);

  /// No description provided for @pdfTechnicalAssistance.
  ///
  /// In pt, this message translates to:
  /// **'ASSISTÊNCIA TÉCNICA'**
  String get pdfTechnicalAssistance;

  /// No description provided for @pdfOrderNumber.
  ///
  /// In pt, this message translates to:
  /// **'ORDEM DE SERVIÇO N°:'**
  String get pdfOrderNumber;

  /// No description provided for @pdfServicesPerformed.
  ///
  /// In pt, this message translates to:
  /// **'Serviços Executados'**
  String get pdfServicesPerformed;

  /// No description provided for @pdfPartName.
  ///
  /// In pt, this message translates to:
  /// **'NOME DA PEÇA'**
  String get pdfPartName;

  /// No description provided for @pdfUnitPrice.
  ///
  /// In pt, this message translates to:
  /// **'Valor Unitário'**
  String get pdfUnitPrice;

  /// No description provided for @pdfLineTotal.
  ///
  /// In pt, this message translates to:
  /// **'Valor Total'**
  String get pdfLineTotal;

  /// No description provided for @pdfPartsTotal.
  ///
  /// In pt, this message translates to:
  /// **'TOTAL PÇ'**
  String get pdfPartsTotal;

  /// No description provided for @pdfLabor.
  ///
  /// In pt, this message translates to:
  /// **'SERVIÇO'**
  String get pdfLabor;

  /// No description provided for @pdfSignatureApproval.
  ///
  /// In pt, this message translates to:
  /// **'VISTO'**
  String get pdfSignatureApproval;

  /// No description provided for @pdfSignatureDate.
  ///
  /// In pt, this message translates to:
  /// **'DATA'**
  String get pdfSignatureDate;

  /// No description provided for @pdfSignatureTechnician.
  ///
  /// In pt, this message translates to:
  /// **'TÉCNICO'**
  String get pdfSignatureTechnician;

  /// No description provided for @pdfSignatureCustomer.
  ///
  /// In pt, this message translates to:
  /// **'CLIENTE'**
  String get pdfSignatureCustomer;

  /// No description provided for @pdfEquipmentOk.
  ///
  /// In pt, this message translates to:
  /// **'O equipamento foi consertado e revisado, estando em perfeitas condições de funcionamento'**
  String get pdfEquipmentOk;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
