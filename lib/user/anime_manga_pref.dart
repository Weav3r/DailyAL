import 'package:dailyanimelist/user/anime_manga_tab_pref.dart';
import 'package:dailyanimelist/user/list_pref.dart';
import 'package:dailyanimelist/util/error/error_reporting.dart';
import 'package:json_annotation/json_annotation.dart';

part 'anime_manga_pref.g.dart';

enum TimezonePref { utc, jst, local }

@JsonSerializable()
class AnimeMangaPagePreferences {
  List<AnimeMangaTabPreference> animeTabs;
  List<AnimeMangaTabPreference> mangaTabs;
  TimezonePref timezonePref;
  String? defaultTab;
  String? defaultAnimeTab;
  String? defaultMangaTab;
  List<ContentCardProps>? contentCardProps;

  AnimeMangaPagePreferences({
    required this.animeTabs,
    required this.mangaTabs,
    this.timezonePref = TimezonePref.local,
    this.defaultTab,
    this.defaultAnimeTab,
    this.defaultMangaTab,
    this.contentCardProps,
  });

  String get defaultTabSelected {
    return defaultTab ?? 'none';
  }

  String get defaultAnimeTabSelected {
    return defaultAnimeTab ?? 'none';
  }

  String get defaultMangaTabSelected {
    return defaultMangaTab ?? 'none';
  }

  factory AnimeMangaPagePreferences.defaultObject() {
    return AnimeMangaPagePreferences(
      animeTabs: defaultAnimeTabs,
      mangaTabs: defaultMangaTabs,
    );
  }

  factory AnimeMangaPagePreferences.fromJson(Map<String, dynamic> json) =>
      _$AnimeMangaPagePreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$AnimeMangaPagePreferencesToJson(this);
}
