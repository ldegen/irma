Rosie = require "rosie"
Factory = Rosie.Factory
extend = Factory.util.extend
module.exports = Factory

lpad = (pad,num)->(""+pad+num).slice -pad.length

Factory.define 'LookupEntry'
  .option 'typeLabel', "Something"
  .option 'padding', ""
  .option 'defaultKey', null
  .sequence 'id'
  .attr 'type', ['typeLabel'], (tl)->tl.toLowerCase()
  .attr 'key', ['key','padding','id','defaultKey'], (key,padding,id,defaultKey)->
    key ? defaultKey ? (lpad padding, id)

Factory.define 'SimpleEntry'
  .extend 'LookupEntry'
  .attr 'label',['label','typeLabel'], (label,tl)->
    Factory.build 'Bilingual', label ?
      de: "Bezeichnung #{tl}"
      en: "Label #{tl}"


Factory.define 'ShortLongEntry'
  .extend 'LookupEntry'
  .attr 'labelShort',['labelShort','typeLabel'], (label,tl)->
    Factory.build 'Bilingual', label ?
      de: "Bezeichnung #{tl} (kurz)"
      en: "Label #{tl} (short)"
  .attr 'labelLong',['labelLong','typeLabel'], (label,tl)->
    Factory.build 'Bilingual', label ?
      de: "Bezeichnung #{tl} (lang)"
      en: "Label #{tl} (long)"

Factory.define 'MaleFemaleEntry'
  .extend 'LookupEntry'
  .attr 'labelFemale',['labelFemale','typeLabel'], (label,tl)->
    Factory.build 'Bilingual', label ?
      de: "Bezeichnung #{tl} (weibl.)"
      en: "Label #{tl} (female)"
  .attr 'labelMale',['labelMale','typeLabel'], (label,tl)->
    Factory.build 'Bilingual', label ?
      de: "Bezeichnung #{tl} (männl.)"
      en: "Label #{tl} (male)"


defaultLookupEntries = (factory, opts)->
  (entries0)->
    entries0 ?=
      '0': id: 0
    entries = {}
    for id,entry of entries0
      entries[id] = Factory.build factory, entry ,opts
    entries

titelEntries = (entries0)->
  entries0 ?=
    '0':
      id: 0
      labelMale: de: "Prof."
      labelFemale: de: "Prof."
    '1':
      id: 1
      labelMale: de: "Dr."
      labelFemale: de:"Dr."
  entries = {}
  for id,entry of entries0
    entries[id] = Factory.build "MaleFemaleEntry", entry , typeLabel:'Titel'
  entries


Factory.define 'RawLookup'
  .attr 'fach',['fach'], defaultLookupEntries 'SimpleEntry',
    typeLabel:'Fach'
    padding:'00000'
  .attr 'fachkollegium', ['fachkollegium'], defaultLookupEntries 'SimpleEntry',
    typeLabel:'Fachkollegium'
    padding:'000'
  .attr 'fachgebiet', ['fachgebiet'], defaultLookupEntries 'SimpleEntry',
    typeLabel:'Fachgebiet'
    padding:'00'
  .attr 'wissenschaftsbereich', ['wissenschaftsbereich'], defaultLookupEntries 'SimpleEntry',
    typeLabel:'Wissenschaftsbereich'
    padding:'0'
  .attr 'peu', ['peu'], defaultLookupEntries 'SimpleEntry',
    typeLabel:'PEU'
    defaultKey:'XXX'
  .attr 'pemu', ['pemu'], defaultLookupEntries 'SimpleEntry',
    typeLabel:'PEMU'
    defaultKey:'XXX'
  .attr 'peo', ['peo'], defaultLookupEntries 'SimpleEntry',
    typeLabel:'PEO'
    defaultKey:'XXXX'
  .attr 'titel',['titel'], titelEntries
  .attr 'bundesland',['bundesland'], defaultLookupEntries 'SimpleEntry',
    typeLabel:'Bundesland'
    defaultKey:'XXX0'
  .attr 'land',['land'], defaultLookupEntries 'SimpleEntry',
    typeLabel:'Land'
    defaultKey:'XXX'
  .attr 'kontinent',['kontinent'], defaultLookupEntries 'SimpleEntry',
    typeLabel:'Kontinent'
    defaultKey:'0'
  .attr 'teilkontinent',['teilkontinent'], defaultLookupEntries 'SimpleEntry',
    typeLabel:'Teilkontinent'
    defaultKey:'00'
Factory.define 'RawFachklassifikation'
  .sequence 'id'
  .attr '_partSn',['id'], (id)->id
  .attr '_partType', 'FACHSYSTEMATIK'
  .attr 'prioritaet', false
  .attr 'wissenschaftsbereich'
  .attr 'fachgebiet'
  .attr 'fachkollegium'
  .attr 'fach'

Factory.define 'RawProgrammklassifikation'
  .attr 'peo',0
  .attr 'pemu',0
  .attr 'peu',0
Factory.define 'Bilingual'
  .attr 'de'
  .attr 'en'
Factory.define 'RawPersonenbeteiligung'
  .attr '_partSn',['personId'], (id)->id
  .sequence 'personId'
  .attr '_partType', 'PER_BETEILIGUNG'
  .attr '_partDeleted', false
  .attr 'referent',false
  .attr 'verstorben',false
  .attr 'showInProjektResultEntry',true
  .attr 'style', 'L'
  .attr 'btrKey', "PAN"

Factory.define 'RawInstitutionsbeteiligung'
  .sequence '_partSn'
  .attr '_partType', 'INS_BETEILIGUNG'
  .attr 'btrKey', 'IAN'
  .attr 'style', 'L'
  .sequence 'institutionId'

Factory.define 'TitelTupel'
  .attr 'anrede',0
  .attr 'teilname',1

Factory.define 'InsTitel'
  .attr 'nameRoot', ['nameRoot'], (name)->
    Factory.build "Bilingual", name ?
      de: 'Name der Wurzelinstitution'
      en: 'Name of Root Institution'
  .attr 'namePostanschrift', 'Name der Wurzelinstitution, Abteilung, usw'

Factory.define 'GeoLocation'
  .attr 'lon'
  .attr 'lat'

Factory.define 'RawRahmenprojekt'
  .sequence 'id'
  .attr 'gz', 'FOO 08/15'
  .attr 'gzAnzeigen', false
  .attr 'titel', ['titel'], (titel)->
    Factory.build "Bilingual", titel ?
      de: "Rahmenprojekttitel"
      en: "Title of Framework Project"

Factory.define 'RawBeteiligtePerson'
  .sequence 'id'
  .attr '_partSn',['id'], (id)->id
  .attr '_partDeleted', false
  .attr '_partType', 'PER'
  .attr 'privatanschrift',false
  .attr 'vorname', 'Vorname'
  .attr 'nachname', 'Nachname'
  .attr 'ort', 'Ortsname'
  .attr 'ortKey', 'DEU12potsdam'
  .attr 'plzVorOrt', '00000'
  .attr 'plzNachOrt',null
  .attr 'titel',['titel'], (titel)->Factory.build 'TitelTupel',titel ? {}
  .attr 'geschlecht','m'
  .attr 'institution',['institution'], (ins)->Factory.build 'InsTitel', ins ? {}
  .attr 'geolocation',['geolocation'], (loc)-> if loc? then Factory.build 'GeoLocation', loc
  .attr 'bundesland',0
  .attr 'land',0

Factory.define 'RawBeteiligteInstitution'
  .sequence 'id'
  .attr '_partSn',['id'], (id)->id
  .attr '_partType', 'INS'
  .attr 'rootId'
  .attr 'einrichtungsart', 5
  .attr 'bundesland', 'DEU12'
  .attr 'ortKey', 'DEU12potsdam'
  .attr 'ort', 'Potsdam'
  .attr 'name',['name'], (name)->
    Factory.build 'Bilingual', name ?
      de: 'Name der Institution'
      en: 'Name of Institution'
  .attr 'nameRoot', ['nameRoot'], (name)->
    Factory.build "Bilingual", name ?
      de: 'Name der Wurzelinstitution'
      en: 'Name of Root Institution'
  .attr 'namePostanschrift', 'Name der Wurzelinstitution, Abteilung, usw'
  .attr 'geolocation',['geolocation'], (loc)-> if loc? then Factory.build 'GeoLocation', loc

Factory.define 'RawAbschlussbericht'
  .attr 'datum', 0
  .attr 'abstract', ['abstract'], (abs)->
    Factory.build 'Bilingual',abs ?
      de:'Deutscher AB Abstract'
      en:'Englischer AB Abstract'
  .attr 'publikationen',['publikationen'], (pubs)->
    (pubs ? []).map (pub)->
      Factory.build 'RawPublikation',pub
Factory.define 'RawPublikation'
  .sequence '_partSn'
  .attr '_partType', 'PUBLIKATION'
  .attr '_partDeleted'
  .attr 'titel', 'Publikationstitel'
  .attr 'position',0
  .attr 'autorHrsg', "Autor / Hrsg."
  .attr 'verweis', null
  .attr 'jahr', 1984
Factory.define 'RawNationaleZuordnung'
  .sequence '_partSn'
  .attr '_partType', 'LAND_BEZUG'
  .attr 'kontinent',1
  .attr 'teilkontinent',12
  .attr 'land',1


Factory.define 'RawProjekt'
  .attr '_partType', 'PRJ'
  .attr '_partSn', -1
  .attr '_partDeleted', false
  .sequence 'id'
  .attr 'hasAb',['abschlussbericht'], (ab)-> ab?
  .attr 'isRahmenprojekt', false
  .attr 'isTeilprojekt',['rahmenprojekt'], (rp)->rp?
  .attr 'pstKey', 'ABG'
  .attr 'gz', 'GZ 08/15'
  .attr 'gzAnzeigen', false
  .attr 'wwwAdresse', "http://www.mein-projekt.de"
  .attr 'rahmenprojekt',['rahmenprojekt'], (rp)->
    if rp? then Factory.build 'RawRahmenprojekt', rp
  .attr 'beginn'
  .attr 'ende'
  .attr 'beteiligteFachrichtungen'
  .attr 'titel', ['titel'], (titel)->
    Factory.build 'Bilingual', titel ?
      de: "Projekttitel"
      en: "Project Title"
  .attr 'antragsart', 'EIN'
  .attr 'abstract', ['abstract'], (abstract)->
    if abstract? then Factory.build 'Bilingual', abstract
  .attr 'fachklassifikationen', ['fachklassifikationen'], (fks)->
    prioSet = (fks ? []).some (fk)->fk.prioritaet
    (fks ? [{wissenschaftsbereich:0,fachkollegium:0,fach:0}]).map (d,i)->
      if not prioSet and not d.prioritaet?
        prioSet=true
        d.prioritaet=true
      Factory.build 'RawFachklassifikation', d
  .attr 'internationalerBezug',['internationalerBezug'], (zs)->
    (zs ? []).map (z)->Factory.build 'RawNationaleZuordnung', z
  .attr 'programmklassifikation', ['programmklassifikation'], (pkl)->
    Factory.build('RawProgrammklassifikation', pkl ? {})
  .attr 'perBeteiligungen', ['perBeteiligungen'] , (bets)->
    (bets ? []).map (bet)->Factory.build 'RawPersonenbeteiligung', bet
  .attr 'insBeteiligungen', ['insBeteiligungen'] , (bets)->
    (bets ? []).map (bet)->Factory.build 'RawInstitutionsbeteiligung', bet

  .attr 'personen',['perBeteiligungen','personen'], (bets,personen0)->
    personen0 ?= {}
    personen = {}
    for bet in bets
      personen[bet.personId]=Factory.build 'RawBeteiligtePerson', {id:bet.personId}
    for perId, person of personen0
      personen[perId] = Factory.build 'RawBeteiligtePerson', person
    personen
  .attr 'institutionen',['insBeteiligungen','institutionen'], (bets,institutionen0)->
    institutionen0 ?= {}
    institutionen = {}
    for bet in bets
      institutionen[bet.institutionId]=Factory.build 'RawBeteiligteInstitution', {id:bet.institutionId}
    for insId, institution of institutionen0
      institutionen[insId] = Factory.build 'RawBeteiligteInstitution', institution
    institutionen
  .attr 'abschlussbericht',['abschlussbericht'],(ab)->
    if ab? then Factory.build 'RawAbschlussbericht', ab

postProcess = (name,factory)->
  factory.after (obj)->
    for attr,value of obj
      # raise error if user 'invented' any new attributes
      throw new Error("Undeclared attribute #{attr} for factory #{name}") if not factory.attrs[attr]

      # remove attributes with undefined value
      delete obj[attr] if typeof value == "undefined"
    obj

postProcess(name,factory) for name, factory of Factory.factories
