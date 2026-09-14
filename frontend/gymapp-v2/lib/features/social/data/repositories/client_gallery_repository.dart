import '../models/client_gallery_model.dart';
import '../services/client_gallery_api_service.dart';
import '../../../../core/network/api_response.dart';

class ClientGalleryRepository {
  final ClientGalleryApiService _apiService;

  ClientGalleryRepository(this._apiService);

  Future<ApiResponse<List<ClientGalleryModel>>> getMyGallery() {
    return _apiService.getMyGallery();
  }

  Future<ApiResponse<ClientGalleryModel>> addToGallery(String imageUrl) {
    return _apiService.addToGallery(imageUrl);
  }

  Future<ApiResponse<void>> deleteGalleryItem(int id) {
    return _apiService.deleteGalleryItem(id);
  }
}
