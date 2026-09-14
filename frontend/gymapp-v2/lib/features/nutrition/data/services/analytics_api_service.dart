import 'package:dio/dio.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import '../models/nutrition_dashboard_model.dart';
import '../models/ai_recipe_suggestion_response_model.dart';
import '../models/diet_program_model.dart';
import 'base_nutrition_service.dart';

class AnalyticsApiService extends BaseNutritionService {
  AnalyticsApiService(super.dioClient);

  Future<ApiResponse<NutritionDashboardModel>> getDashboardData([int? programId, int? targetUserId]) async {
    try {
      final queryParams = <String, dynamic>{};
      if (programId != null) queryParams['programId'] = programId;
      if (targetUserId != null) queryParams['targetUserId'] = targetUserId;

      final response = await dioClient.dio.get<Map<String, dynamic>>(
        '/nutrition/analytics/dashboard',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => NutritionDashboardModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<void>> updateNutritionGoals(Map<String, dynamic> goals) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/analytics/goals',
        data: goals,
      );
      return ApiResponse.fromJson(response.data ?? <String, dynamic>{}, (json) {});
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<AiRecipeSuggestionResponseModel>> suggestRecipe({int? programId}) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/ai/suggest-recipe',
        queryParameters: programId != null ? {'programId': programId} : null,
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => AiRecipeSuggestionResponseModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<DietProgramModel>> saveRecipe(int mealId, int recipeId) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/ai/save-recipe',
        queryParameters: {
          'mealId': mealId,
          'recipeId': recipeId,
        },
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => DietProgramModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<AiRecipeSuggestionResponseModel?>> getLastAiSuggestion() async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>('/nutrition/ai/last-suggestion');
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => json == null ? null : AiRecipeSuggestionResponseModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }
}
