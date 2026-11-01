import '../engine/rational.dart';
import 'squad.dart';

Rational _q(int n, int d) => Rational(BigInt.from(n), BigInt.from(d));

PlayerProfile _p(
  String name,
  PlayerRole role,
  int n,
  int d, {
  bool available = true,
}) => PlayerProfile(
  name: name,
  role: role,
  importance: _q(n, d),
  available: available,
);

/// Kurált NB I-es keretek: támadás/védelem, utolsó 5 forma, kulcsemberek.
/// Nem élő sérülésjelentés — pillanatkép a modellhez.
TeamDirectory curatedHungarianSquads() {
  return TeamDirectory([
    TeamProfile(
      id: 'ferencvaros',
      name: 'Ferencváros',
      aliases: ['ftc', 'fradi'],
      attack: _q(8, 5),
      defense: _q(7, 5),
      recentForm: [
        FormResult.win,
        FormResult.win,
        FormResult.draw,
        FormResult.win,
        FormResult.loss,
      ],
      players: [
        _p('Dibusz Dénes', PlayerRole.goalkeeper, 1, 5),
        _p('Makreckis Cebio', PlayerRole.defender, 1, 10),
        _p('Civic Eldar', PlayerRole.defender, 1, 10),
        _p('Zachariassen Kristoffer', PlayerRole.midfielder, 1, 8),
        _p('Barnabás Varga', PlayerRole.forward, 1, 4),
        _p('Adama Traoré', PlayerRole.forward, 1, 8),
      ],
    ),
    TeamProfile(
      id: 'puskas',
      name: 'Puskás Akadémia',
      aliases: ['puskás akadémia', 'pafe'],
      attack: _q(6, 5),
      defense: _q(6, 5),
      recentForm: [
        FormResult.draw,
        FormResult.win,
        FormResult.win,
        FormResult.loss,
        FormResult.draw,
      ],
      players: [
        _p('Pászka Lóránd', PlayerRole.defender, 1, 8),
        _p('Levi Colchado', PlayerRole.midfielder, 1, 8),
        _p('Soisalo Mikael', PlayerRole.forward, 1, 6),
        _p('Nagy Zsolt', PlayerRole.forward, 1, 6),
      ],
    ),
    TeamProfile(
      id: 'debrecen',
      name: 'Debrecen',
      aliases: ['dvsc', 'loki'],
      attack: _q(11, 10),
      defense: _q(1, 1),
      recentForm: [
        FormResult.loss,
        FormResult.draw,
        FormResult.win,
        FormResult.loss,
        FormResult.draw,
      ],
      players: [
        _p('Szécsi Dániel', PlayerRole.goalkeeper, 1, 8),
        _p('Dzsudzsák Balázs', PlayerRole.midfielder, 1, 5),
        _p('Barany Donát', PlayerRole.forward, 1, 6),
      ],
    ),
    TeamProfile(
      id: 'kisvarda',
      name: 'Kisvárda',
      recentForm: [
        FormResult.loss,
        FormResult.loss,
        FormResult.draw,
        FormResult.win,
        FormResult.loss,
      ],
      attack: _q(9, 10),
      defense: _q(19, 20),
      players: [
        _p('Melnyik András', PlayerRole.goalkeeper, 1, 8),
        _p('Navrátil Jaroslav', PlayerRole.forward, 1, 5, available: false),
        _p('Matić Bernardo', PlayerRole.midfielder, 1, 8),
      ],
    ),
    TeamProfile(
      id: 'ujpest',
      name: 'Újpest',
      aliases: ['ujpest'],
      attack: _q(21, 20),
      defense: _q(1, 1),
      recentForm: [
        FormResult.win,
        FormResult.loss,
        FormResult.draw,
        FormResult.win,
        FormResult.draw,
      ],
      players: [
        _p('Banai Szabolcs', PlayerRole.goalkeeper, 1, 8),
        _p('Ljujić Matija', PlayerRole.midfielder, 1, 6),
        _p('Gajdos Mátyás', PlayerRole.forward, 1, 7),
      ],
    ),
    TeamProfile(
      id: 'diosgyor',
      name: 'Diósgyőr',
      aliases: ['dVTK', 'dvtk'],
      attack: _q(1, 1),
      defense: _q(19, 20),
      recentForm: [
        FormResult.draw,
        FormResult.loss,
        FormResult.win,
        FormResult.loss,
        FormResult.win,
      ],
      players: [
        _p('Odiljon Hamrobekov', PlayerRole.midfielder, 1, 7),
        _p('Gera Dániel', PlayerRole.forward, 1, 6),
      ],
    ),
    TeamProfile(
      id: 'zalaegerszeg',
      name: 'Zalaegerszeg',
      aliases: ['zte'],
      attack: _q(19, 20),
      defense: _q(9, 10),
      recentForm: [
        FormResult.loss,
        FormResult.draw,
        FormResult.loss,
        FormResult.draw,
        FormResult.win,
      ],
      players: [
        _p('Szántó Bálint', PlayerRole.midfielder, 1, 8),
        _p('Szendrei Norbert', PlayerRole.forward, 1, 7),
      ],
    ),
    TeamProfile(
      id: 'paks',
      name: 'Paksi FC',
      aliases: ['paks'],
      attack: _q(23, 20),
      defense: _q(21, 20),
      recentForm: [
        FormResult.win,
        FormResult.draw,
        FormResult.win,
        FormResult.win,
        FormResult.loss,
      ],
      players: [
        _p('Szabó János', PlayerRole.defender, 1, 7),
        _p('Böde Dániel', PlayerRole.forward, 1, 5),
        _p('Windecker József', PlayerRole.midfielder, 1, 6),
      ],
    ),
    TeamProfile(
      id: 'honved',
      name: 'Honvéd',
      aliases: ['budapest honvéd'],
      attack: _q(9, 10),
      defense: _q(9, 10),
      recentForm: [
        FormResult.draw,
        FormResult.loss,
        FormResult.loss,
        FormResult.draw,
        FormResult.win,
      ],
      players: [
        _p('Kukec Andrej', PlayerRole.midfielder, 1, 7),
        _p('Zsótér Donát', PlayerRole.forward, 1, 6),
      ],
    ),
    TeamProfile(
      id: 'fehervar',
      name: 'Fehérvár',
      aliases: ['videoton', 'vidi'],
      attack: _q(11, 10),
      defense: _q(21, 20),
      recentForm: [
        FormResult.win,
        FormResult.draw,
        FormResult.loss,
        FormResult.win,
        FormResult.draw,
      ],
      players: [
        _p('Nagy Zsombor', PlayerRole.goalkeeper, 1, 8),
        _p('Katona Mátyás', PlayerRole.midfielder, 1, 7),
        _p('Schön Szabolcs', PlayerRole.forward, 1, 5),
      ],
    ),
    TeamProfile(
      id: 'nyiregyhaza',
      name: 'Nyíregyháza',
      attack: _q(17, 20),
      defense: _q(9, 10),
      recentForm: [
        FormResult.loss,
        FormResult.loss,
        FormResult.draw,
        FormResult.loss,
        FormResult.draw,
      ],
      players: [
        _p('Nagy Patrik', PlayerRole.midfielder, 1, 8),
        _p('Bekő Péter', PlayerRole.forward, 1, 7),
      ],
    ),
    TeamProfile(
      id: 'mtk',
      name: 'MTK Budapest',
      aliases: ['mtk'],
      attack: _q(6, 5),
      defense: _q(11, 10),
      recentForm: [
        FormResult.win,
        FormResult.win,
        FormResult.draw,
        FormResult.loss,
        FormResult.win,
      ],
      players: [
        _p('Kata Mihály', PlayerRole.midfielder, 1, 6),
        _p('Molnár Gábor', PlayerRole.forward, 1, 6),
        _p('Kádár Tamás', PlayerRole.defender, 1, 7),
      ],
    ),
  ]);
}
