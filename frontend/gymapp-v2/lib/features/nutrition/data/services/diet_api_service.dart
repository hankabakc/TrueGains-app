import 'package:dio/dio.dart';
import 'package:gymapp_v2/core/network/error_message.dart';
import 'package:gymapp_v2/core/network/api_response.dart';
import '../models/diet_program_model.dart';
import '../models/diet_entry_model.dart';
import '../models/diet_assignment_model.dart';
import '../models/meal_entry_model.dart';
import 'base_nutrition_service.dart';

class DietApiService extends BaseNutritionService {
  DietApiService(super.dioClient);

  Future<ApiResponse<DailyDietLogModel>> getDailyDietLog(String date) async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>(
        '/diet/daily-log',
        queryParameters: {'date': date},
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => DailyDietLogModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<MealEntryModel>> togglePlannedMeal(
    String date,
    int mealId,
    bool consumed, {
    List<int>? ingredientIds,
  }) async {
    try {
      final params = <String, dynamic>{
        'date': date,
        'mealId': mealId,
        'consumed': consumed,
      };
      if (ingredientIds != null && ingredientIds.isNotEmpty) {
        params['ingredientIds'] = ingredientIds;
      }
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/diet/log/toggle-planned',
        queryParameters: params,
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => MealEntryModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<List<DietProgramModel>>> getMyPrograms() async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>('/nutrition/diet/my-programs');
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => (json as List).map((e) => DietProgramModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<DietProgramModel>> getMainProgram() async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>('/nutrition/diet/main');
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

  Future<ApiResponse<DietProgramModel>> getProgramById(int id) async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>('/nutrition/diet/$id');
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

  Future<ApiResponse<DietProgramModel>> createProgram(String name, bool isMain) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/diet/create',
        queryParameters: {'name': name, 'isMain': isMain},
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

  Future<ApiResponse<DietProgramModel>> addIngredientsBulk(
    int mealId,
    List<Map<String, dynamic>> requests,
  ) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/diet/meals/$mealId/ingredients/bulk',
        data: requests,
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

  Future<ApiResponse<DietProgramModel>> addIngredient(
    int mealId,
    double amount, {
    int? foodId,
    int? recipeId,
    String? note,
    bool ignoreOverride = false,
  }) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/diet/meals/$mealId/ingredients',
        queryParameters: {
          if (foodId != null) 'foodId': foodId,
          if (recipeId != null) 'recipeId': recipeId,
          'amount': amount,
          if (note != null) 'note': note,
          'ignoreOverride': ignoreOverride,
        },
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => DietProgramModel.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<DietProgramModel>> updateDietRecipeIngredient(int ingredientId, dynamic updatedRecipeJson) async {
    try {
      final response = await dioClient.dio.put<Map<String, dynamic>>(
        '/nutrition/diet/meals/ingredients/$ingredientId/recipe',
        data: updatedRecipeJson,
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

  Future<ApiResponse<DietProgramModel>> deleteMeal(int mealId) async {
    try {
      final response = await dioClient.dio.delete<Map<String, dynamic>>('/nutrition/diet/meals/$mealId');
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

  Future<ApiResponse<DietProgramModel>> renameProgram(int id, String name) async {
    try {
      final response = await dioClient.dio.put<Map<String, dynamic>>(
        '/nutrition/diet/$id/rename',
        queryParameters: {'name': name},
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

  Future<ApiResponse<DietProgramModel>> deleteMealIngredient(int ingredientId) async {
    try {
      final response = await dioClient.dio.delete<Map<String, dynamic>>(
        '/nutrition/diet/meals/ingredients/$ingredientId',
      );
      return ApiResponse.fromJson(
        response.data ?? {},
        (json) => DietProgramModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<DietProgramModel>> updateMealIngredientAmount(int ingredientId, double amount) async {
    try {
      final response = await dioClient.dio.put<Map<String, dynamic>>(
        '/nutrition/diet/meals/ingredients/$ingredientId',
        queryParameters: {'amount': amount},
      );
      return ApiResponse.fromJson(
        response.data ?? {},
        (json) => DietProgramModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<void>> deleteProgram(int id) async {
    try {
      final response = await dioClient.dio.delete<Map<String, dynamic>>('/nutrition/diet/$id');
      return ApiResponse.fromJson(response.data ?? <String, dynamic>{}, (_) {});
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<void>> activateProgram(int id) async {
    try {
      final response = await dioClient.dio.put<Map<String, dynamic>>('/nutrition/diet/$id/activate');
      return ApiResponse.fromJson(response.data ?? <String, dynamic>{}, (_) {});
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<void>> updateProgramGoals(int id, Map<String, dynamic> goals) async {
    try {
      final response = await dioClient.dio.put<Map<String, dynamic>>(
        '/nutrition/diet/$id/goals',
        data: goals,
      );
      return ApiResponse.fromJson(response.data ?? <String, dynamic>{}, (json) {});
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<List<DietProgramModel>>> getCoachDietTemplates() async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>('/nutrition/diet/templates');
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => (json as List).map((e) => DietProgramModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<DietProgramModel>> createDietTemplate(String name) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/diet/templates/create',
        queryParameters: {'name': name},
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

  Future<ApiResponse<DietProgramModel>> assignDietTemplate(int templateId, int clientId) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/diet/assign/$templateId/$clientId',
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

  Future<ApiResponse<List<DietAssignmentModel>>> getTemplateAssignments(int templateId) async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>(
        '/nutrition/diet/templates/$templateId/assignments',
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => (json as List).map((e) => DietAssignmentModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<List<DietAssignmentModel>>> fetchDietAssignments() async {
    try {
      final response = await dioClient.dio.get<Map<String, dynamic>>('/nutrition/diet/assignments');
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => (json as List).map((e) => DietAssignmentModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }


  Future<ApiResponse<DietProgramModel>> approveOrphan(int id, bool keep) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/diet/programs/approve-orphan/$id',
        queryParameters: {'keep': keep},
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

  Future<ApiResponse<void>> unassignTemplate(int templateId, int clientId) async {
    try {
      final response = await dioClient.dio.delete<Map<String, dynamic>>(
        '/nutrition/diet/templates/$templateId/unassign/$clientId',
      );
      return ApiResponse.fromJson(response.data ?? <String, dynamic>{}, (_) {});
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  // --- Meal Logging (Daily) ---

  Future<ApiResponse<MealEntryModel>> logMeal({
    required String mealTypeStr,
    required List<Map<String, dynamic>> items,
    DateTime? date,
  }) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/meal-logs/log',
        data: {
          'mealType': mealTypeStr,
          'items': items,
          if (date != null) 'takenDatetime': date.toUtc().toIso8601String(),
        },
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => MealEntryModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<MealEntryModel>> addFoodToMealLog({
    required String mealTypeStr,
    required int foodId,
    required double amount,
    bool ignoreOverride = false,
  }) async {
    try {
      final response = await dioClient.dio.post<Map<String, dynamic>>(
        '/nutrition/meal-logs/$mealTypeStr/add-food',
        queryParameters: {
          'foodId': foodId,
          'amount': amount,
          'ignoreOverride': ignoreOverride,
        },
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => MealEntryModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<List<MealEntryModel>>> getDailyMealLogs([DateTime? date]) async {
    try {
      final queryDate = date ?? DateTime.now();
      final dateStr = queryDate.toIso8601String().split('T')[0];
      final response = await dioClient.dio.get<Map<String, dynamic>>(
        '/nutrition/meal-logs/daily',
        queryParameters: {'date': dateStr},
      );
      return ApiResponse.fromJson(
        response.data ?? <String, dynamic>{},
        (json) => (json as List).map((e) => MealEntryModel.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<void>> deleteMealItem(int itemId) async {
    try {
      final response = await dioClient.dio.delete<Map<String, dynamic>>('/nutrition/meal-logs/items/$itemId');
      if (response.statusCode == 204 || response.data == null) {
        return ApiResponse(success: true, message: 'Silindi', timestamp: '');
      }
      return ApiResponse.fromJson(response.data ?? <String, dynamic>{}, (_) {});
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }

  Future<ApiResponse<void>> deleteMealEntry(int entryId) async {
    try {
      final response = await dioClient.dio.delete<Map<String, dynamic>>('/nutrition/meal-logs/$entryId');
      return ApiResponse.fromJson(response.data ?? <String, dynamic>{}, (_) {});
    } on DioException catch (e) {
      return handleError(e);
    } catch (e) {
      return ApiResponse.error(friendlyError(e));
    }
  }
}
