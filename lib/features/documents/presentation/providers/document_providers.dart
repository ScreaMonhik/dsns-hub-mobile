import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../data/models/document_models.dart';

final documentSearchQueryProvider = StateProvider<String?>((ref) => null);

final documentsPagingControllerProvider =
    StateProvider<PagingController<int, DocumentModel>?>((ref) => null);
