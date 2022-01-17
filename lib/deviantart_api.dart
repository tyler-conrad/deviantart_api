library deviantart_api;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart' as eq;

import 'creds.dart' as creds;
import 'logger.dart' as l;

const String apiVersion = '20210526';

const String baseAPIPath = 'https://www.deviantart.com/api/v1/oauth2';
const String browsePart = '/browse';
const String dailyPart = '/dailydeviations';
const String popularPart = '/popular';
const String moreLikeThisPart = '/morelikethis';
const String previewPart = '/preview';
const String newestPart = '/newest';
const String tagsPart = '/tags';
const String searchPart = '/search';
const String topicsPart = '/topics';
const String topicPart = '/topic';
const String topTopicsPart = '/toptopics';

String _buildPath({required List<String> parts}) {
  return '$baseAPIPath${parts.join()}';
}

class User extends eq.Equatable {
  final String userID;
  final String userName;
  final String userIcon;

  @override
  List<Object> get props => [userID, userName, userIcon];

  @override
  bool get stringify => true;

  const User({required this.userID, required this.userName, required this.userIcon});

  factory User.fromJSON({required Map<String, dynamic> decoded}) {
    return User(
        userID: decoded['userid'],
        userName: decoded['username'],
        userIcon: decoded['usericon']);
  }
}

class Image extends eq.Equatable {
  final String src;
  final int width;
  final int height;
  final bool transparency;

  @override
  List<Object> get props => [src, width, height];

  @override
  bool get stringify => true;

  const Image({required this.src, required this.width, required this.height, required this.transparency});

  factory Image.fromJSON({required Map<String, dynamic> decoded}) {
    return Image(
      src: decoded['src'],
      width: decoded['width'],
      height: decoded['height'],
      transparency: decoded['transparency'],
    );
  }
}

class FullsizeImage extends Image {
  final int fileSize;

  @override
  List<Object> get props => [src, width, height, fileSize];

  @override
  bool get stringify => true;

  const FullsizeImage(
      {required String src,
        required int width,
        required int height,
        required bool transparency,
        required this.fileSize})
      : super(src: src, width: width, height: height, transparency: transparency);

  factory FullsizeImage.fromJSON({required Map<String, dynamic> decoded}) {
    return FullsizeImage(
        src: decoded['src'],
        width: decoded['width'],
        height: decoded['height'],
        transparency: decoded['transparency'],
        fileSize: decoded['filesize']);
  }
}

class DeviationItem extends eq.Equatable {
  final String id;
  final bool isDeleted;
  final bool isPublished;
  final String title;
  final String category;
  final User author;
  final Image? preview;
  final FullsizeImage? content;
  final List<Image> thumbs;

  @override
  List<Object?> get props => [
    id,
    isDeleted,
    isPublished,
    title,
    category,
    author,
    preview,
    content, ...thumbs
  ];

  @override
  bool get stringify => true;

  const DeviationItem(
      {required this.id,
        required this.isDeleted,
        required this.isPublished,
        required this.title,
        required this.category,
        required this.author,
        required this.preview,
        required this.content,
        required this.thumbs});

  factory DeviationItem.fromJSON({required Map<String, dynamic> decoded}) {
    Image? preview = decoded['preview'] == null
        ? null
        : Image.fromJSON(decoded: decoded['preview']);
    FullsizeImage? content = decoded['content'] == null
        ? null
        : FullsizeImage.fromJSON(decoded: decoded['content']);

    return DeviationItem(
        id: decoded['deviationid'],
        isDeleted: decoded['is_deleted'],
        isPublished: decoded['is_published'],
        title: decoded['title'],
        category: decoded['category'],
        author: User.fromJSON(decoded: decoded['author']),
        preview: preview,
        content: content,
        thumbs: decoded['thumbs']
            .map<Image>((thumb) => Image.fromJSON(decoded: thumb))
            .toList());
  }
}

abstract class ResponseBase {}

class BrowseResponse extends ResponseBase with eq.EquatableMixin {
  final List<DeviationItem> items;

  @override
  List<Object> get props => items;

  @override
  bool get stringify => true;

  BrowseResponse({required this.items});

  factory BrowseResponse.fromJSON({required List<dynamic> decoded}) {
    return BrowseResponse(
        items: decoded
            .map((item) => DeviationItem.fromJSON(decoded: item))
            .toList());
  }
}

class Collection extends eq.Equatable {
  final int folderID;
  final String name;
  final User owner;

  @override
  List<Object> get props => [folderID, name, owner];

  @override
  bool get stringify => true;

  const Collection({required this.folderID, required this.name, required this.owner});

  factory Collection.fromJSON({required Map<String, dynamic> decoded}) {
    return Collection(
        folderID: decoded['folderid'],
        name: decoded['name'],
        owner: User.fromJSON(decoded: decoded['owner']));
  }
}

class SuggestedCollection extends eq.Equatable {
  final Collection collection;
  final List<DeviationItem> deviations;

  @override
  List<Object> get props => [collection, ...deviations];

  @override
  bool get stringify => true;

  const SuggestedCollection({required this.collection, required this.deviations});

  factory SuggestedCollection.fromJSON(
      {required Map<String, dynamic> decoded}) {
    return SuggestedCollection(
        collection: Collection.fromJSON(decoded: decoded['collection']),
        deviations: decoded['deviations']
            .map<DeviationItem>((item) => DeviationItem.fromJSON(decoded: item))
            .toList());
  }
}

class MoreLikeThisResponse extends ResponseBase with eq.EquatableMixin {
  final String seed;
  final User author;
  final List<DeviationItem> moreFromArtist;
  final List<DeviationItem> moreFromDA;
  final List<SuggestedCollection> suggestedCollections;

  @override
  List<Object?> get props =>
      [seed, author, moreFromArtist, moreFromDA, suggestedCollections];

  @override
  bool? get stringify => true;

  MoreLikeThisResponse(
      {required this.seed,
        required this.author,
        required this.moreFromArtist,
        required this.moreFromDA,
        required this.suggestedCollections});

  factory MoreLikeThisResponse.fromJSON(
      {required Map<String, dynamic> decoded}) {
    List<dynamic> suggestedCollections = decoded['suggested_collections'] ?? [];
    return MoreLikeThisResponse(
        seed: decoded['seed'],
        author: User.fromJSON(decoded: decoded['author']),
        moreFromArtist: decoded['more_from_artist']
            .map<DeviationItem>((item) => DeviationItem.fromJSON(decoded: item))
            .toList(),
        moreFromDA: decoded['more_from_da']
            .map<DeviationItem>((item) => DeviationItem.fromJSON(decoded: item))
            .toList(),
        suggestedCollections: suggestedCollections
            .map<SuggestedCollection>(
                (item) => SuggestedCollection.fromJSON(decoded: item))
            .toList());
  }
}

class TagSearchResponse extends ResponseBase with eq.EquatableMixin {
  final List<String> tags;

  @override
  List<Object> get props => tags;

  @override
  bool get stringify => true;

  TagSearchResponse({required this.tags});

  factory TagSearchResponse.fromJSON({required List<dynamic> decoded}) {
    return TagSearchResponse(
        tags: decoded.map<String>((tag) => tag['tag_name']).toList());
  }
}

class Topic extends eq.Equatable {
  final String name;
  final String canonicalName;
  final List<DeviationItem> examples;

  @override
  List<Object> get props => [name, canonicalName, ...examples];

  @override
  bool get stringify => true;

  const Topic(
      {required this.name,
        required this.canonicalName,
        required this.examples});

  factory Topic.fromJSON({required Map<String, dynamic> decoded}) {
    return Topic(
        name: decoded['name'],
        canonicalName: decoded['canonical_name'],
        examples: decoded['example_deviations']
            .map<DeviationItem>((item) => DeviationItem.fromJSON(decoded: item))
            .toList());
  }
}

class ListTopicsResponse extends ResponseBase with eq.EquatableMixin {
  final List<Topic> topics;

  @override
  List<Object> get props => topics;

  @override
  bool get stringify => true;

  ListTopicsResponse({required this.topics});

  factory ListTopicsResponse.fromJSON({required List<dynamic> decoded}) {
    return ListTopicsResponse(
        topics: decoded
            .map<Topic>((topic) => Topic.fromJSON(decoded: topic))
            .toList());
  }
}

abstract class _RequestBase<R extends ResponseBase,
T extends _ResponseCallbackArgs> {
  final void Function(T) callback;
  async.Future<R> send({required Client client});
  Map<String, String> get _params;

  _RequestBase({required this.callback});
}

class _DailyRequest extends _RequestBase<BrowseResponse, _NullCallbackArgs>
    with eq.EquatableMixin {
  final DateTime date;

  @override
  List<Object> get props => ['$date'];

  @override
  bool get stringify => true;

  String get year => '${date.year}'.padLeft(4, '0');
  String get month => '${date.month}'.padLeft(2, '0');
  String get day => '${date.day}'.padLeft(2, '0');

  @override
  Map<String, String> get _params => {'date': '$year-$month-$day'};

  @override
  async.Future<BrowseResponse> send({required Client client}) async {
    http.Response resp = await _get(
        path: _buildPath(parts: [browsePart, dailyPart]),
        client: client,
        params: _params);
    callback(_NullCallbackArgs());
    return BrowseResponse.fromJSON(
        decoded: convert.json.decode(resp.body)['results']);
  }

  _DailyRequest(
      {required this.date, required void Function(_NullCallbackArgs) callback})
      : super(callback: callback);
}

abstract class _OffsetLimitPaginatorRequest<R extends ResponseBase,
T extends _ResponseCallbackArgs> extends _RequestBase<R, T>
    with eq.EquatableMixin {
  final int _offset;
  final int _limit;

  @override
  List<Object?> get props => [_offset, _limit];

  @override
  Map<String, String> get _params => {
    'offset': '$_offset',
    'limit': '$_limit',
  };

  _OffsetLimitPaginatorRequest(
      {required int offset,
        required int limit,
        required void Function(T) callback})
      : _offset = offset,
        _limit = limit,
        super(callback: callback);
}

enum TimeRange {
  now,
  oneWeek,
  oneMonth,
  allTime,
}

class _PopularRequest extends _OffsetLimitPaginatorRequest<BrowseResponse,
    _SingleDirectionPaginatorResponseMetadata> with eq.EquatableMixin {
  final String? _search;
  final TimeRange? _timeRange;

  static String _stringFromeTimeRange(TimeRange timeRange) {
    switch (timeRange) {
      case TimeRange.now:
        return 'now';
      case TimeRange.oneWeek:
        return '1week';
      case TimeRange.oneMonth:
        return '1month';
      case TimeRange.allTime:
        return 'alltime';
    }
  }

  @override
  List<Object?> get props => super.props..addAll([_search, _timeRange]);

  @override
  bool get stringify => true;

  @override
  Map<String, String> get _params {
    Map<String, String> params = {
      'offset': '$_offset',
      'limit': '$_limit',
    };
    if (_search != null) {
      params['q'] = _search!;
    }
    if (_timeRange != null) {
      params['timerange'] = _stringFromeTimeRange(_timeRange!);
    }
    return params;
  }

  @override
  async.Future<BrowseResponse> send({required Client client}) async {
    http.Response resp = await _get(
      path: _buildPath(parts: [browsePart, popularPart]),
      client: client,
      params: _params,
    );
    Map<String, dynamic> decoded = convert.json.decode(resp.body);
    callback(
        _SingleDirectionPaginatorResponseMetadata.fromJSON(decoded: decoded));
    return BrowseResponse.fromJSON(decoded: decoded['results']);
  }

  _PopularRequest(
      {required int offset,
        required int limit,
        String? search,
        TimeRange? timeRange,
        required void Function(_SingleDirectionPaginatorResponseMetadata)
        callback})
      : _search = search,
        _timeRange = timeRange,
        super(offset: offset, limit: limit, callback: callback);
}

class _NewestRequest extends _OffsetLimitPaginatorRequest<BrowseResponse,
    _SingleDirectionPaginatorResponseMetadata> with eq.EquatableMixin {
  final String? _search;

  @override
  List<Object?> get props => super.props..addAll([_search]);

  @override
  bool get stringify => true;

  @override
  Map<String, String> get _params {
    Map<String, String> offsetLimitParams = super._params;

    return _search == null ? offsetLimitParams : offsetLimitParams
      ..addAll({
        'q': _search!,
      });
  }

  @override
  async.Future<BrowseResponse> send({required Client client}) async {
    http.Response resp = await _get(
        path: _buildPath(parts: [browsePart, newestPart]),
        client: client,
        params: _params);
    Map<String, dynamic> decoded = convert.json.decode(resp.body);
    callback(
        _SingleDirectionPaginatorResponseMetadata.fromJSON(decoded: decoded));
    return BrowseResponse.fromJSON(decoded: decoded['results']);
  }

  _NewestRequest(
      {required int offset,
        required int limit,
        String? search,
        required void Function(_SingleDirectionPaginatorResponseMetadata)
        callback})
      : _search = search,
        super(offset: offset, limit: limit, callback: callback);
}

class _TagsRequest extends _OffsetLimitPaginatorRequest<BrowseResponse,
    _SingleDirectionPaginatorResponseMetadata> with eq.EquatableMixin {
  final String _tag;

  @override
  List<Object?> get props => super.props..addAll([_tag]);

  @override
  Map<String, String> get _params => super._params
    ..addAll({
      'tag': _tag,
    });

  @override
  async.Future<BrowseResponse> send({required Client client}) async {
    http.Response resp = await _get(
        path: _buildPath(parts: [browsePart, tagsPart]),
        client: client,
        params: _params);
    Map<String, dynamic> decoded = convert.json.decode(resp.body);
    callback(
        _SingleDirectionPaginatorResponseMetadata.fromJSON(decoded: decoded));
    return BrowseResponse.fromJSON(decoded: decoded['results']);
  }

  _TagsRequest(
      {required int offset,
        required int limit,
        required String tag,
        required void Function(_SingleDirectionPaginatorResponseMetadata)
        callback})
      : _tag = tag,
        super(offset: offset, limit: limit, callback: callback);
}

class MoreLikeThisRequest
    extends _RequestBase<MoreLikeThisResponse, _NullCallbackArgs>
    with eq.EquatableMixin {
  final String _seed;

  @override
  List<Object> get props => [_seed];

  @override
  bool get stringify => true;

  @override
  Map<String, String> get _params => {'seed': _seed};

  @override
  async.Future<MoreLikeThisResponse> send({required Client client}) async {
    http.Response resp = await _get(
        path: _buildPath(parts: [browsePart, moreLikeThisPart, previewPart]),
        client: client,
        params: _params);
    callback(_NullCallbackArgs());
    return MoreLikeThisResponse.fromJSON(
        decoded: convert.json.decode(resp.body));
  }

  MoreLikeThisRequest(
      {required String seed,
        required void Function(_NullCallbackArgs) callback})
      : _seed = seed,
        super(callback: callback);
}

class TagSearchRequest
    extends _RequestBase<TagSearchResponse, _NullCallbackArgs>
    with eq.EquatableMixin {
  final String _tag;

  @override
  List<Object> get props => [_tag];

  @override
  bool get stringify => true;

  @override
  Map<String, String> get _params => {
    'tag_name': _tag,
  };

  @override
  async.Future<TagSearchResponse> send({required Client client}) async {
    http.Response resp = await _get(
        path: _buildPath(parts: [browsePart, tagsPart, searchPart]),
        client: client,
        params: _params);
    callback(_NullCallbackArgs());
    return TagSearchResponse.fromJSON(
        decoded: convert.json.decode(resp.body)['results']);
  }

  TagSearchRequest(
      {required String tag, required void Function(_NullCallbackArgs) callback})
      : _tag = tag,
        super(callback: callback);
}

class TopTopicsRequest
    extends _RequestBase<ListTopicsResponse, _NullCallbackArgs>
    with eq.EquatableMixin {
  @override
  List<Object> get props => [];

  @override
  bool get stringify => true;

  @override
  Map<String, String> get _params => {};

  @override
  async.Future<ListTopicsResponse> send({required Client client}) async {
    http.Response resp = await _get(
        path: _buildPath(parts: [browsePart, topTopicsPart]),
        client: client,
        params: _params);
    callback(_NullCallbackArgs());
    return ListTopicsResponse.fromJSON(
        decoded: convert.json.decode(resp.body)['results']);
  }

  TopTopicsRequest({required void Function(_NullCallbackArgs) callback})
      : super(callback: callback);
}

class _ListTopicsRequest extends _OffsetLimitPaginatorRequest<
    ListTopicsResponse,
    _SingleDirectionPaginatorResponseMetadata> with eq.EquatableMixin {
  @override
  bool get stringify => true;

  @override
  async.Future<ListTopicsResponse> send({required Client client}) async {
    http.Response resp = await _get(
        path: _buildPath(parts: [browsePart, topicsPart]),
        client: client,
        params: _params);
    Map<String, dynamic> decoded = convert.json.decode(resp.body);
    callback(
        _SingleDirectionPaginatorResponseMetadata.fromJSON(decoded: decoded));
    return ListTopicsResponse.fromJSON(decoded: decoded['results']);
  }

  _ListTopicsRequest(
      {required int offset,
        required int limit,
        required void Function(_SingleDirectionPaginatorResponseMetadata)
        callback})
      : super(offset: offset, limit: limit, callback: callback);
}

class _BrowseTopicRequest extends _OffsetLimitPaginatorRequest<BrowseResponse,
    _SingleDirectionPaginatorResponseMetadata> with eq.EquatableMixin {
  final String _name;

  @override
  List<Object?> get props => super.props..addAll([_name]);

  @override
  bool get stringify => true;

  @override
  Map<String, String> get _params => super._params..addAll({'topic': _name});

  @override
  async.Future<BrowseResponse> send({required Client client}) async {
    http.Response resp = await _get(
        path: _buildPath(parts: [browsePart, topicPart]),
        client: client,
        params: _params);
    Map<String, dynamic> decoded = convert.json.decode(resp.body);
    callback(
        _SingleDirectionPaginatorResponseMetadata.fromJSON(decoded: decoded));
    return BrowseResponse.fromJSON(decoded: decoded['results']);
  }

  _BrowseTopicRequest(
      {required int offset,
        required int limit,
        required void Function(_SingleDirectionPaginatorResponseMetadata)
        callback,
        required String name})
      : _name = name,
        super(offset: offset, limit: limit, callback: callback);
}

abstract class _Offset<T extends Comparable> {
  final T min;
  final T max;
  final T defaultValue;

  T _offset;
  T get offset => _offset;
  set offset(T offset);

  void reset() => offset = defaultValue;

  _Offset({required this.min, required this.max, required this.defaultValue})
      : _offset = defaultValue;
}

class WrappingOffset<T extends Comparable> extends _Offset<T> {
  @override
  set offset(T offset) {
    if (offset.compareTo(this.min) < 0) {
      l.logger.w(
          'Attempted to set Offset.offset to a value less than Offset.min: $offset, setting to Offset.max');
      offset = this.max;
    } else if (offset.compareTo(this.max) > 0) {
      l.logger.w(
          'Attempted to set Offset.offset to a value greater than Offset.max: $offset, setting to Offset.min');
      offset = this.min;
    }
    _offset = offset;
  }

  WrappingOffset({required T min, required T max, required T defaultValue})
      : super(min: min, max: max, defaultValue: defaultValue);
}

class NonWrappingOffset<T extends Comparable> extends _Offset<T> {
  @override
  set offset(offset) {
    if (offset.compareTo(this.min) < 0) {
      l.logger.w(
          'Attempted to set Offset.offset to a value less than Offset.min: $offset, setting to Offset.min');
      offset = this.min;
    } else if (offset.compareTo(this.max) > 0) {
      l.logger.w(
          'Attempted to set Offset.offset to a value greater than Offset.max: $offset, setting to Offset.max');
      offset = this.max;
    }
    _offset = offset;
  }

  NonWrappingOffset({required T min, required T max, required T defaultValue})
      : super(min: min, max: max, defaultValue: defaultValue);
}

class IntBasedNonWrappingOffset extends NonWrappingOffset<int> {
  IntBasedNonWrappingOffset(
      {required int min, required int max, required int defaultValue})
      : super(min: min, max: max, defaultValue: defaultValue);

  IntBasedNonWrappingOffset.standard()
      : this(min: 0, max: 50000, defaultValue: 0);
}

class Limit<T extends Comparable> {
  final T min;
  final T max;
  final T defaultValue;

  T _limit;
  T get limit => _limit;
  set limit(T limit) {
    if (limit.compareTo(min) < 0) {
      l.logger.w('limit less than min: $limit, resetting to min');
      limit = min;
    } else if (limit.compareTo(max) > 0) {
      l.logger.w('limit greater than max: $limit, resetting to max');
      limit = max;
    }
    _limit = limit;
  }

  Limit({required this.min, required this.max, required this.defaultValue})
      : _limit = defaultValue;
}

class IntBasedLimit extends Limit<int> {
  IntBasedLimit({required int min, required int max, required int defaultValue})
      : super(min: min, max: max, defaultValue: defaultValue);
  IntBasedLimit.standard() : this(min: 1, max: 120, defaultValue: 10);
}

abstract class _PaginatorBase<R extends ResponseBase, O extends Comparable,
L extends Comparable> {
  final _Offset<O> offset;
  final Limit<L> limit;

  bool wrappedBackward = false;
  bool wrappedForward = false;

  Future<R> _pageRequest({required Client client});
  Future<R> next({required Client client});
  Future<R> prev({required Client client});

  _PaginatorBase({required this.offset, required this.limit});
}

abstract class SingleDirectionPaginatorBase<R extends ResponseBase>
    extends _PaginatorBase<R, int, int> {
  abstract _SingleDirectionPaginatorResponseMetadata metadata;

  @override
  Future<R> next({required Client client}) {
    if (!metadata.hasMore) {
      wrappedForward = true;
      offset.reset();
    } else {
      offset.offset = metadata.nextOffset!;
    }
    return _pageRequest(client: client);
  }

  @override
  Future<R> prev({required Client client}) {
    int newOffset = offset.offset - limit.limit;
    wrappedBackward = wrappedForward ? true : newOffset < offset.min;
    offset.offset = newOffset;
    return _pageRequest(client: client);
  }

  SingleDirectionPaginatorBase(
      {required IntBasedNonWrappingOffset offset, required IntBasedLimit limit})
      : super(offset: offset, limit: limit);
}

class DailyPaginator extends _PaginatorBase<BrowseResponse, DateTime, int> {
  static DateTime get now {
    DateTime current = DateTime.now();
    return DateTime(current.year, current.month, current.day);
  }

  @override
  async.Future<BrowseResponse> _pageRequest({required Client client}) {
    return _DailyRequest(date: offset.offset, callback: (_) {})
        .send(client: client);
  }

  @override
  async.Future<BrowseResponse> next({required Client client}) {
    DateTime newOffset = offset.offset.add(Duration(days: limit.limit));
    wrappedForward = wrappedForward ? true : newOffset.isAfter(offset.max);
    offset.offset = newOffset;
    return _pageRequest(client: client);
  }

  @override
  async.Future<BrowseResponse> prev({required Client client}) {
    DateTime newOffset = offset.offset.subtract(Duration(days: limit.limit));
    wrappedBackward = wrappedBackward ? true : newOffset.isBefore(newOffset);
    offset.offset = newOffset;
    return _pageRequest(client: client);
  }

  DailyPaginator(
      {required WrappingOffset<DateTime> offset, required Limit<int> limit})
      : super(offset: offset, limit: limit);
}

class PopularPaginator extends SingleDirectionPaginatorBase<BrowseResponse> {
  final String? _search;
  final TimeRange? _timeRange;

  @override
  _SingleDirectionPaginatorResponseMetadata metadata =
  _SingleDirectionPaginatorResponseMetadata.standard();

  @override
  Future<BrowseResponse> _pageRequest({required Client client}) {
    return _PopularRequest(
        offset: offset.offset,
        limit: limit.limit,
        search: _search,
        timeRange: _timeRange,
        callback: (_SingleDirectionPaginatorResponseMetadata newMetadata) {
          metadata = newMetadata;
        }).send(client: client);
  }

  PopularPaginator(
      {required IntBasedNonWrappingOffset offset,
        required IntBasedLimit limit,
        String? search,
        TimeRange? timeRange})
      : _search = search,
        _timeRange = timeRange,
        super(offset: offset, limit: limit);
}

class NewestPaginator extends SingleDirectionPaginatorBase<BrowseResponse> {
  final String? _search;

  @override
  _SingleDirectionPaginatorResponseMetadata metadata =
  _SingleDirectionPaginatorResponseMetadata.standard();

  @override
  async.Future<BrowseResponse> _pageRequest({required Client client}) {
    return _NewestRequest(
        offset: offset.offset,
        limit: limit.limit,
        search: _search,
        callback: (_SingleDirectionPaginatorResponseMetadata newMetadata) {
          metadata = newMetadata;
        }).send(client: client);
  }

  NewestPaginator(
      {required IntBasedNonWrappingOffset offset,
        required IntBasedLimit limit,
        String? search})
      : _search = search,
        super(offset: offset, limit: limit);
}

class TagsPaginator extends SingleDirectionPaginatorBase<BrowseResponse> {
  final String _tag;

  @override
  _SingleDirectionPaginatorResponseMetadata metadata =
  _SingleDirectionPaginatorResponseMetadata.standard();

  @override
  async.Future<BrowseResponse> _pageRequest({required Client client}) {
    return _TagsRequest(
        offset: offset.offset,
        limit: limit.limit,
        tag: _tag,
        callback: (_SingleDirectionPaginatorResponseMetadata newMetadata) {
          metadata = newMetadata;
        }).send(client: client);
  }

  TagsPaginator(
      {required IntBasedNonWrappingOffset offset,
        required IntBasedLimit limit,
        required String tag})
      : _tag = tag,
        super(offset: offset, limit: limit);
}

class ListTopicsPaginator
    extends SingleDirectionPaginatorBase<ListTopicsResponse> {
  @override
  _SingleDirectionPaginatorResponseMetadata metadata =
  _SingleDirectionPaginatorResponseMetadata.standard();

  @override
  async.Future<ListTopicsResponse> _pageRequest({required Client client}) {
    return _ListTopicsRequest(
        offset: offset.offset,
        limit: limit.limit,
        callback: (_SingleDirectionPaginatorResponseMetadata newMetadata) {
          metadata = newMetadata;
        }).send(client: client);
  }

  ListTopicsPaginator(
      {required IntBasedNonWrappingOffset offset, required IntBasedLimit limit})
      : super(offset: offset, limit: limit);
}

class BrowseTopicPaginator
    extends SingleDirectionPaginatorBase<BrowseResponse> {
  final String _name;

  @override
  _SingleDirectionPaginatorResponseMetadata metadata =
  _SingleDirectionPaginatorResponseMetadata.standard();

  @override
  async.Future<BrowseResponse> _pageRequest({required Client client}) {
    return _BrowseTopicRequest(
        offset: offset.offset,
        limit: limit.limit,
        callback: (_SingleDirectionPaginatorResponseMetadata newMetadata) {
          metadata = newMetadata;
        },
        name: _name)
        .send(client: client);
  }

  BrowseTopicPaginator(
      {required IntBasedNonWrappingOffset offset,
        required IntBasedLimit limit,
        required String name})
      : _name = name,
        super(offset: offset, limit: limit);
}

abstract class _ResponseCallbackArgs {}

class _NullCallbackArgs extends _ResponseCallbackArgs {}

class _SingleDirectionPaginatorResponseMetadata extends _ResponseCallbackArgs {
  bool hasMore;
  int? nextOffset;
  int? errorCode;

  _SingleDirectionPaginatorResponseMetadata(
      {required this.hasMore,
        required this.nextOffset,
        required this.errorCode});

  _SingleDirectionPaginatorResponseMetadata.standard()
      : this(hasMore: true, nextOffset: 0, errorCode: null);

  factory _SingleDirectionPaginatorResponseMetadata.fromJSON(
      {required Map<String, dynamic> decoded}) {
    return _SingleDirectionPaginatorResponseMetadata(
        hasMore: decoded['has_more'],
        nextOffset: decoded['next_offset'],
        errorCode: decoded['error_code']);
  }
}

class APIError extends eq.Equatable {
  final String error;
  final String desc;
  final Map<String, dynamic> details;
  final int? code;

  @override
  List<Object?> get props =>
      [error, desc, code, ...details.entries.toList()];

  @override
  bool get stringify => true;

  const APIError(
      {required this.error,
        required this.desc,
        required this.details,
        this.code});

  factory APIError.fromJSON({required Map<String, dynamic> decoded}) {
    return APIError(
        error: decoded['error'],
        desc: decoded['error_description'],
        details: decoded['error_details'] ?? {},
        code: decoded['error_code']);
  }
}

Duration _pow2Duration(int index) {
  return Duration(seconds: pow(2, index).toInt());
}

class MaxAccessTokenResetRetriesExceededException implements Exception {
  final String message;

  const MaxAccessTokenResetRetriesExceededException([this.message = '']);

  @override
  String toString() => 'MaxAccessTokenResetRetriesExceededException: $message';
}

async.Future<http.Response> _get(
    {required String path,
      required Client client,
      Map<String, String>? params,
      Map<String, String>? headers,
      int accessTokenResetRetries = 0}) async {
  if(accessTokenResetRetries > 3) {
    throw MaxAccessTokenResetRetriesExceededException('retries: $accessTokenResetRetries');
  }
  Map<String, String> paramsWithAccessToken = {
    'access_token': client._accessToken,
    'mature_content': 'false',
  };
  paramsWithAccessToken.addAll(params ?? {});

  Map<String, String> headersWithAPIversion = {
    'dA-minor-version': apiVersion,
  };
  headersWithAPIversion.addAll(headers ?? {});

  http.Response resp = await http.get(
      Uri.parse(path).replace(queryParameters: paramsWithAccessToken),
      headers: headersWithAPIversion);
  if (resp.statusCode == 401) {
    await Future.delayed(_pow2Duration(accessTokenResetRetries));
    Client apiWithNewAccessToken = await ClientBuilder.resetAccessToken(client);
    resp = await _get(
      path: path,
      client: apiWithNewAccessToken,
      params: params,
      headers: headers,
      accessTokenResetRetries: accessTokenResetRetries + 1,
    );
  }
  return resp;
}

final DateTime earliestDateSupportedByDailyPaginator = DateTime(2010, 1, 1);

class Client {
  String _accessToken;

  Future<R> next<R extends ResponseBase, O extends Comparable,
  L extends Comparable, P extends _PaginatorBase<R, O, L>>(P paginator) {
    return paginator.next(client: this);
  }

  Future<R> previous<R extends ResponseBase, O extends Comparable,
  L extends Comparable, P extends _PaginatorBase<R, O, L>>(P paginator) {
    return paginator.prev(client: this);
  }

  Future<R> send<R extends ResponseBase, T extends _ResponseCallbackArgs,
  U extends _RequestBase<R, T>>({required U request}) {
    return request.send(client: this);
  }

  static DailyPaginator dailyPaginator(
      {WrappingOffset<DateTime>? offset, Limit<int>? limit}) {
    return DailyPaginator(
        offset: offset ??
            WrappingOffset<DateTime>(
                min: earliestDateSupportedByDailyPaginator,
                max: DailyPaginator.now,
                defaultValue: DailyPaginator.now),
        limit: limit ?? Limit<int>(min: 1, max: 365, defaultValue: 1));
  }

  static PopularPaginator popularPaginator(
      {IntBasedNonWrappingOffset? offset,
        IntBasedLimit? limit,
        String? search,
        TimeRange? timeRange}) {
    return PopularPaginator(
        offset: offset ?? IntBasedNonWrappingOffset.standard(),
        limit: limit ?? IntBasedLimit.standard(),
        search: search,
        timeRange: timeRange);
  }

  static NewestPaginator newestPaginator(
      {IntBasedNonWrappingOffset? offset,
        IntBasedLimit? limit,
        String? search}) {
    return NewestPaginator(
        offset: offset ?? IntBasedNonWrappingOffset.standard(),
        limit: IntBasedLimit.standard(),
        search: search);
  }

  static TagsPaginator tagsPaginator({
    IntBasedNonWrappingOffset? offset,
    IntBasedLimit? limit,
    required String tag,
  }) {
    return TagsPaginator(
        offset: offset ?? IntBasedNonWrappingOffset.standard(),
        limit: limit ?? IntBasedLimit(min: 1, max: 50, defaultValue: 10),
        tag: tag);
  }

  static ListTopicsPaginator topicsListPaginator(
      {IntBasedNonWrappingOffset? offset, IntBasedLimit? limit}) {
    return ListTopicsPaginator(
        offset: offset ?? IntBasedNonWrappingOffset.standard(),
        limit: limit ?? IntBasedLimit(min: 1, max: 10, defaultValue: 10));
  }

  static BrowseTopicPaginator browseTopicPaginator(
      {IntBasedNonWrappingOffset? offset,
        IntBasedLimit? limit,
        required String topicName}) {
    return BrowseTopicPaginator(
        offset: offset ?? IntBasedNonWrappingOffset.standard(),
        limit: limit ?? IntBasedLimit(min: 1, max: 24, defaultValue: 10),
        name: topicName);
  }

  static MoreLikeThisRequest moreLikeThis({required String seed}) {
    return MoreLikeThisRequest(seed: seed, callback: (_) {});
  }

  static TagSearchRequest tagSearch({required String tag}) {
    return TagSearchRequest(tag: tag, callback: (_) {});
  }

  static TopTopicsRequest topTopics() {
    return TopTopicsRequest(callback: (_) {});
  }

  Client({required String accessToken}) : _accessToken = accessToken;
}

class ClientBuilder {
  static Future<String> _accessToken() async {
    http.Response resp = await http.post(
      Uri.parse('https://www.deviantart.com/oauth2/token'),
      body: {
        'client_id': creds.clientId,
        'client_secret': creds.clientSecret,
        'grant_type': 'client_credentials',
      },
    );
    return convert.json.decode(resp.body)['access_token'];
  }

  static Future<Client> build() async {
    String accessToken = await _accessToken();
    return Client(accessToken: accessToken);
  }

  static Future<Client> resetAccessToken(Client client) async {
    String accessToken = await _accessToken();
    return client.._accessToken = accessToken;
  }
}
