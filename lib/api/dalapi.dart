import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:dailyanimelist/api/credmal.dart';
import 'package:dailyanimelist/api/malconnect.dart';
import 'package:dailyanimelist/api/maluser.dart';
import 'package:dailyanimelist/cache/cachemanager.dart';
import 'package:dailyanimelist/cache/history_data.dart';
import 'package:dailyanimelist/constant.dart';
import 'package:dal_api/handlers/handler_core.dart';
import 'package:dal_api/services/helpers.dart';
import 'package:dal_commons/commons.dart';
import 'package:dal_commons/dal_commons.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/src/media_type.dart';

enum FeatureFlag { aireviews }

class DalApi {
  static DalApi _internal = DalApi._();
  static DalApi i = _internal;
  late Future<Servers?> _dalConfigFuture;
  late Future<String> _preferredServer;
  late Future<Map<int, ScheduleData>> _scheduleForMalIds;
  Map<int, ScheduleData> _scheduleForMalIdsSync = {};
  bool _debugMode = kDebugMode;

  Future<Servers?> get dalConfigFuture async {
    return _dalConfigFuture;
  }

  Future<Map<int, ScheduleData>> get scheduleForMalIds async {
    return await _scheduleForMalIds.then((value) {
      _scheduleForMalIdsSync = value;
      return value;
    });
  }

  Map<int, ScheduleData> get scheduleForMalIdsSync => _scheduleForMalIdsSync;

  void onScheduleLoaded(void Function() callback) {
    _scheduleForMalIds.then((value) {
      callback();
    });
  }

  DalApi._() {
    _dalConfigFuture = _getDalConfigFuture();
    _preferredServer = _getPreferredServer();
    _scheduleForMalIds = _getScheduleForMalIds();
  }

  void resetScheduleForMalIds() {
    _scheduleForMalIds = _getScheduleForMalIds(fromCache: false);
  }

  Future<Servers> _getDalConfigFuture() async {
    final refUrl =
        '${CredMal.appConfigUrl}/${CredMal.buildVariant.name}/serverConfigV3${_debugMode ? 'Dev' : ''}.json';
    return Servers.fromJson(
      jsonDecode(await _getConfig(refUrl)),
    );
  }

  Future<String> _getConfig(String url) async {
    try {
      return (await MalConnect.retryGetNoH(url)).body;
    } catch (e) {
      logDal(e);
      return CredMal.defaultConfig;
    }
  }

  Future<String> _getPreferredServer() async {
    final config = (await _dalConfigFuture);
    final pfServers = config?.preferredServers;
    final strategy = config?.strategy ?? 'random';
    String? preferredServer;
    if (!nullOrEmpty(pfServers)) {
      if (strategy.equals('random')) {
        preferredServer =
            pfServers?.elementAt(Random().nextInt(pfServers.length)).url;
      } else if (strategy.equals('load')) {
        pfServers?.sort((a, b) => (a.load ?? 0) - (b.load ?? 0));
        preferredServer = pfServers?.first.url;
      } else if (strategy.equals('max_load_random')) {
        final availablePfServers = pfServers
            ?.where((e) => (config?.maxLoad ?? 0) < (e.load ?? 0))
            .toList();
        preferredServer = availablePfServers
            ?.elementAt(Random().nextInt(availablePfServers.length))
            .url;
      }
    }
    return preferredServer ?? 'http://0.0.0.0:8080/';
  }

  Future<dynamic> httpGet(String endpoint,
      [fromCache = true, int? timeInhours]) async {
    return MalConnect.getContent(
      '${await _preferredServer}$endpoint',
      fromCache: fromCache,
      retryOnFail: false,
      withNoHeaders: true,
      timeinHours: timeInhours,
    );
  }

  Future<DalRenderContent> getContent(String category, int id,
      {bool fromCache = true, bool htmlOnly = false}) async {
    return DalRenderContent.fromMap(
      await httpGet('$category/$id?htmlOnly=$htmlOnly', fromCache),
      category,
    );
  }

  Future<List<String>?> getPictures(int id, String category) async {
    final Map<String, dynamic>? chara = await httpGet('$category/$id/pics');
    return chara != null
        ? ((chara['pictures'] ?? <String>[]) as List<dynamic>)
            .map<String>((e) => e)
            .toList()
        : [];
  }

  Future<SearchResult> searchFeaturedArticles({
    String? query,
    int page = 1,
    String? tag,
    String category = "featured",
    String additonalCategory = "anime",
    String containerName = "news-list",
    int? id,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'tag': tag,
      'additonalCategory': additonalCategory,
      'containerName': containerName,
      'id': id,
      'query': query,
    };
    return FeaturedResult.fromMap(
      await httpGet('$category?${buildQueryParams(queryParams)}', true, 2),
    );
  }

  Future<DataUnion?> getCharaPeopleInfo(int id, DataUnionType type) async {
    return JikanV4Result.fromJson(type, await httpGet('${type.name}/$id')).data;
  }

  Future<dynamic> getRecomData({
    int? id,
    String category = 'anime',
    int page = 1,
  }) async {
    return JikanV4Result.fromJson(
      DataUnionType.recomm_base,
      await httpGet('recommendations?id=$id&category=$category&page=$page'),
    )?.data;
  }

  Future<int?> getRandom(String category) async {
    final result = await MalConnect.getContent(
      '${CredMal.jikanV4}random/$category?sfw=false',
      withNoHeaders: true,
      fromCache: false,
      retryOnFail: false,
    );

    if (result != null && result is Map && result.containsKey('data')) {
      return result['data']['mal_id'];
    } else {
      return null;
    }
  }

  Future<int?> getRandomFromList(String category, String status) async {
    try {
      final result = await MalUser.getMyContentList(
        category: category,
        status: status,
        username: '@me',
        limit: 500,
      );
      if (!nullOrEmpty(result.data)) {
        int limit = result.data!.length;
        var node = result.data![Random().nextInt(limit)]?.content;
        return node?.id;
      }
    } catch (e) {
      logDal(e);
    }
    return null;
  }

  Future<CharacterListData> getCharacters([int page = 1]) async {
    return CharacterListData.fromJson(await httpGet('characters?page=$page'));
  }

  Future<PeopleListData> getPeople([int page = 1]) async {
    return PeopleListData.fromJson(await httpGet('people?page=$page'));
  }

  Future<List<RecomCompare>> getRecommendations(
    String category, [
    int page = 1,
  ]) async {
    return RecomListData.fromJson(
          await httpGet('recommendations?category=$category&page=$page'),
        ).data ??
        [];
  }

  Future<List<AnimeReviewHtml>> getReviews({
    int? id,
    String? category,
    int page = 1,
  }) async {
    return ListData<AnimeReviewHtml>.fromJson(
          await httpGet('reviews?category=$category&id=$id&page=$page'),
          (v) => AnimeReviewHtml.fromJson(v),
        ).data ??
        [];
  }

  Future<List<ScheduleData>> getSchedules({
    String type = 'all',
    SeasonType? season,
    int? year,
    bool fromCache = true,
  }) async {
    return ListData<ScheduleData>.fromJson(
            await httpGet(
                'schedules?${buildQueryParams({
                      'type': type,
                      'season': season?.name,
                      'year': year
                    })}',
                fromCache),
            (p0) => ScheduleData.fromJson(p0))?.data ??
        [];
  }

  Future<Map<int, ScheduleData>> _getScheduleForMalIds({
    String type = 'all',
    SeasonType? season,
    int? year,
    bool fromCache = true,
  }) async {
    return HashMap.fromEntries((await getSchedules(
            season: season, type: type, year: year, fromCache: fromCache))
        .map((e) => MapEntry(PathUtils.getIdUrl(e.relatedLinks?.mal), e))
        .where((e) => e.key != null)
        .map((e) => MapEntry(e.key!, e.value)));
  }

  Future<SearchResult> searchInterestStacks({
    int? id,
    String? category,
    int? categoryId,
    int page = 1,
    String? type,
    String? query,
  }) async {
    final list = await searchInterestStacksAsList(
      category: category,
      categoryId: categoryId,
      id: id,
      page: page,
      query: query,
      type: type,
    );
    return SearchResult(
        data: list.map((e) => BaseNode(content: e)).toList(),
        paging: Paging(
          previous: page.toString(),
          next: (page + 1).toString(),
        ));
  }

  Future<List<InterestStack>> searchInterestStacksAsList({
    int? id,
    String? category,
    int? categoryId,
    int page = 1,
    String? type,
    String? query,
  }) async {
    final result = await _getIntrestStacks(
        InterestStackType.search, id, category, categoryId, page, type, query);
    return ListData.fromJson(
          result,
          ((p0) => InterestStack.fromJson(p0)),
        ).data ??
        [];
  }

  Future<dynamic> _getIntrestStacks(
      InterestStackType stackType,
      int? id,
      String? category,
      int? categoryId,
      int? page,
      String? type,
      String? query) async {
    return await httpGet(
      'stacks/${stackType.name}?${buildQueryParams({
            'id': id,
            'category': category,
            'categoryId': categoryId,
            'page': page,
            'type': type,
            'query': query,
          })}',
    );
  }

  Future<List<InterestStack>> getInterestStackList({
    int? id,
    String? category,
    int? categoryId,
    int page = 1,
    String? type,
  }) async {
    final result = await _getIntrestStacks(
        InterestStackType.content, id, category, categoryId, page, type, null);
    return ListData.fromJson(
          result,
          ((p0) => InterestStack.fromJson(p0)),
        ).data ??
        [];
  }

  Future<InterestStackDetailed> getInterestStackDetailed(int id) async {
    final result = await _getIntrestStacks(
        InterestStackType.detailed, id, null, null, null, null, null);
    return InterestStackDetailed.fromMap(result);
  }

  Future<UserAbout?> getUserAbout(String username) async {
    final result = await httpGet(
      'users/about?${buildQueryParams({'username': username})}',
      false,
    );
    if (result is Map) {
      var data = result['data'];
      if (data is Map) {
        var about = data['about']?.toString();
        if (about != null) {
          return UserAbout(about, data['modern'] ?? false);
        }
      }
    }
    return null;
  }

  Future<FriendV4List> getUserFriends(String username) async {
    return JikanV4Result.fromJson(
      DataUnionType.friend,
      await httpGet(
        'users/friends?${buildQueryParams({'username': username})}',
        false,
      ),
    ).data as FriendV4List;
  }

  Future<ContentAllCharData> getAllCharsAndStaff(
      String category, int id) async {
    return ContentAllCharData.fromJson(
      await httpGet('content/characters?${buildQueryParams({
            'category': category,
            'id': id
          })}'),
    );
  }

  Future<ClubDetails> getClubData(int id) async {
    return ClubDetails.fromJson(await httpGet('clubs?id=$id', false) ?? {});
  }

  Future<List<ForumHtml>> getClubTopics(int id, int offset) async {
    return _mapAsList<ForumHtml>(
      await httpGet('clubs/type?id=$id&type=forum&offset=$offset', false),
      ForumHtml.fromJson,
    );
  }

  Future<List<Member>> getClubMember(int id, int offset) async {
    return _mapAsList<Member>(
      await httpGet('clubs/type?id=$id&type=members&offset=$offset', false),
      Member.fromJson,
    );
  }

  Future<List<Comment>> getClubComments(int id, int offset) async {
    return _mapAsList<Comment>(
      await httpGet('clubs/type?id=$id&type=comments&offset=$offset', false),
      Comment.fromJson,
    );
  }

  Future<UserHistoryData> getUserHistory(String username,
      {String? type}) async {
    return UserHistoryData.fromJson(
      await httpGet(
        'users/history?${buildQueryParams({
              'username': username,
              'type': type
            })}',
        false,
      ),
    );
  }

  Future<List<GenreType>> getGenreTypes(String category) async {
    return _mapAsList<GenreType>(
      await httpGet('genres?category=$category'),
      GenreType.fromJson,
    );
  }

  Future<dynamic> _apiGET(String endpoint) async {
    final apiURL = await _getAPIBaseUrl();
    return MalConnect.getContent(
      '$apiURL/$endpoint',
      retryOnFail: false,
      withNoHeaders: true,
      includeNsfw: false,
      headers: _headers,
    );
  }

  Map<String, String> get _headers {
    return {
      'Authorization': 'Bearer ${CredMal.apiSecret}',
    };
  }

  Future<AnimeGraph> getAnimeGraph(int id) async {
    return AnimeGraph.fromJson(
      await _apiGET(
        'anime/$id/related',
      ),
    );
  }

  Future<bool> isFeatureEnabled(FeatureFlag flag) {
    return _dalConfigFuture.then((value) {
      return value?.featureFlags?[flag.name] ?? false;
    });
  }

  Future<ContentReviewSummary?> getReviewsSummary(List<String> reviews) async {
    try {
      final apiURL = '${await _getAPIBaseUrl()}/reviews';
      logDal('Sending reviews to $apiURL');
      final response = await http.post(
        Uri.parse(apiURL),
        headers: _headers,
        body: jsonEncode(reviews),
      );
      final body = response.body;
      return ContentReviewSummary.fromJson(jsonDecode(body));
    } catch (e) {
      logDal(e);
      return null;
    }
  }

  Future<String> getSignedImageUrl(String type, String id) async {
    final response = await _apiGET('types/$type/images/$id');
    return response['signedURL'];
  }

  Future<void> saveImage(
      String type, String id, Uint8List data, String extension) async {
    final apiURL = await _getAPIBaseUrl();
    http.MultipartRequest request = http.MultipartRequest(
      'POST',
      Uri.parse('$apiURL/types/$type/images/$id'),
    );
    request.headers.addAll({
      'Authorization': 'Bearer ${CredMal.apiSecret}',
    });
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        data,
        filename: '$id.image',
        contentType: MediaType('image', extension),
      ),
    );
    final response = await request.send();
    if (response.statusCode != 200) {
      throw Exception('Failed to save image');
    }
  }

  Future<String> _getAPIBaseUrl() async =>
      ((await _dalConfigFuture)?.dalAPIUrl ?? CredMal.apiURL);

  Future<void> removeImage(String type, String id) async {
    final baseUrl = await _getAPIBaseUrl();
    final url = '$baseUrl/types/$type/images/$id';
    final response = await http.delete(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${CredMal.apiSecret}',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete image');
    }
    await CacheManager.instance.setValue(url, '');
  }
}

class UserAbout {
  final String about;
  final bool modern;
  const UserAbout(this.about, this.modern);
}

List<T> _mapAsList<T>(data, T Function(Map<String, dynamic>) mapper) {
  if (data is Map) {
    final list = data['data'];
    if (list is List) {
      return list
          .map((e) {
            if (e == null) {
              return null;
            } else {
              return mapper(e);
            }
          })
          .where((e) => e != null)
          .map((e) => e!)
          .toList();
    }
  }
  return [];
}
