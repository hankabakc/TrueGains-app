import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/offline_cache.dart';
import '../models/food_model.dart';
import '../models/ocr_scan_response_model.dart';
import '../models/meal_history_model.dart';
import '../models/meal_template_model.dart';
import '../models/recipe_model.dart';
import 'base_nutrition_service.dart';

class FoodApiService extends BaseNutritionService {
  FoodApiService(super.dioClient);

  Future<ApiResponse<List<FoodModel>>> searchFood(String query) async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>(
        '/nutrition/foods/search',
        queryParameters: {'query': query},
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => (json as List).map((e) => FoodModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      // KR16 (G-71): sunucuya ulaşılamıyorsa telefondaki katalogda aranır. Sunucu cevap verdiyse aranmaz.
      if (OfflineCacheInterceptor.isUnreachable(e)) {
        final ApiResponse<List<FoodModel>> catalog = await getCatalog();
        if (catalog.success && catalog.data != null) {
          final String q = query.trim().toLowerCase();
          return ApiResponse<List<FoodModel>>(
            success: true,
            message: 'Çevrimdışı arama',
            data: catalog.data!
                .where((FoodModel f) => f.name.toLowerCase().contains(q) || (f.brand?.toLowerCase().contains(q) ?? false))
                .toList(),
            timestamp: DateTime.now().toIso8601String(),
          );
        }
      }
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  /// Görünür besin kataloğunun tamamı (KR16, G-71). Başarılı yanıtı okuma önbelleği saklar; internetsizken
  /// [searchFood] bunun üzerinden cihazda arar.
  Future<ApiResponse<List<FoodModel>>> getCatalog() async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>('/nutrition/foods/catalog');
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => (json as List).map((e) => FoodModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<FoodModel>> getFoodDetails(int id, {bool ignoreOverride = false}) async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>(
        '/nutrition/foods/$id',
        queryParameters: {'ignoreOverride': ignoreOverride},
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => FoodModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<FoodModel>> getFoodByBarcode(String barcode) async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>('/nutrition/foods/barcode/$barcode');
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => FoodModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<FoodModel>> createFood(FoodModel food) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/foods',
        data: food.toCreateJson(),
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => FoodModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<FoodModel>> overrideFood(int id, FoodModel food) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/foods/$id/override',
        data: food.toJson(),
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => FoodModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<void>> deleteOverride(int id) async {
    try {
      final response = await dioClient.dio.delete<Map<String, dynamic>>('/nutrition/foods/$id/override');
      return ApiResponse.fromJson(response.data ?? <String, dynamic>{}, (_) {});
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<List<FoodModel>>> getOverriddenFoods() async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>('/nutrition/foods/overridden');
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => (json as List).map((item) => FoodModel.fromJson(item as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<List<FoodModel>>> getMyCustomFoods() async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>('/nutrition/foods/mine');
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => (json as List).map((item) => FoodModel.fromJson(item as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<List<MealHistoryModel>>> getRecentGroupedFoods() async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>('/nutrition/foods/recent-grouped');
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => (json as List).map((e) => MealHistoryModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<List<FoodModel>>> getRecentFoods() async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>('/nutrition/foods/recent');
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => (json as List).map((e) => FoodModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<List<RecipeModel>>> getRecipes([String? query]) async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>(
        '/nutrition/recipes',
        queryParameters: query != null ? {'query': query} : null,
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => (json as List).map((e) => RecipeModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<RecipeModel>> getRecipeById(int id) async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>(
        '/nutrition/recipes/$id',
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => RecipeModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<List<MealTemplateModel>>> getTemplates() async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>('/nutrition/templates');
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => (json as List).map((e) => MealTemplateModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<MealTemplateDetailModel>> getTemplateDetail(int id) async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>('/nutrition/templates/$id');
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => MealTemplateDetailModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<MealTemplateModel>> createTemplate(String name) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/templates',
        queryParameters: {'name': name},
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => MealTemplateModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<void>> updateTemplate(int id, Map<String, dynamic> data) async {
    try {
      final response = await dioClient.dio.put<Map<String, dynamic>>(
        '/nutrition/templates/$id',
        data: data,
      );
      return ApiResponse.fromJson(response.data ?? <String, dynamic>{}, (_) {});
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<void>> deleteTemplate(int id) async {
    try {
      final response = await dioClient.dio.delete<Map<String, dynamic>>('/nutrition/templates/$id');
      return ApiResponse.fromJson(response.data ?? <String, dynamic>{}, (_) {});
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<OcrScanResponseModel>> scanFoodImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: imageFile.name,
        ),
      });

      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/ocr/scan',
        data: formData,
      );

      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => OcrScanResponseModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }
}
