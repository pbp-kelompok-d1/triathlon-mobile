# Django Fixes Required for Flutter

## Problem 1: Reviews not working (404/403 errors)

The current DRF endpoints use `@permission_classes([IsAuthenticated])` which doesn't work with Flutter's `pbp_django_auth` session cookies.

### Solution: Add these new endpoints to `place/views.py`

Add this code right after the `api_add_place` function:

```python
# ============================================
# FLUTTER-COMPATIBLE REVIEW ENDPOINTS
# ============================================

@require_POST
@csrf_exempt
def api_add_review_flutter(request, pk):
    """Add review - follows api_add_place pattern for Flutter compatibility"""
    if not request.user.is_authenticated:
        return JsonResponse({'success': False, 'error': 'Login required'}, status=401)
    
    try:
        place = get_object_or_404(Place, pk=pk)
        
        # Get data from form data (same pattern as api_add_place)
        rating = request.POST.get('rating', 0)
        comment = request.POST.get('comment', '')
        
        # Validate rating
        try:
            rating = int(rating)
            if not 1 <= rating <= 5:
                return JsonResponse({'success': False, 'error': 'Rating harus 1-5'}, status=400)
        except (ValueError, TypeError):
            return JsonResponse({'success': False, 'error': 'Rating tidak valid'}, status=400)
        
        # Check if user already reviewed
        if Review.objects.filter(place=place, user=request.user).exists():
            return JsonResponse({'success': False, 'error': 'Anda sudah memberikan review'}, status=400)
        
        review = Review.objects.create(
            place=place,
            user=request.user,
            rating=rating,
            comment=comment
        )
        return JsonResponse({'success': True, 'id': review.id}, status=201)
        
    except Exception as e:
        print(f"Error adding review: {e}")
        return JsonResponse({'success': False, 'error': str(e)}, status=400)


@require_POST
@csrf_exempt
def api_delete_review_flutter(request, review_id):
    """Delete review - follows api_add_place pattern for Flutter compatibility"""
    if not request.user.is_authenticated:
        return JsonResponse({'success': False, 'error': 'Login required'}, status=401)
    
    try:
        review = get_object_or_404(Review, pk=review_id)
        
        # Only owner or admin can delete
        if review.user != request.user and not is_admin(request.user):
            return JsonResponse({'success': False, 'error': 'Unauthorized'}, status=403)
        
        review.delete()
        return JsonResponse({'success': True})
        
    except Exception as e:
        print(f"Error deleting review: {e}")
        return JsonResponse({'success': False, 'error': str(e)}, status=400)
```

### Then update `place/urls.py` to use these new endpoints:

Replace the old review URL patterns (or add if not exists):

```python
# In place/urls.py, update/add these patterns:
path('api/places/<int:pk>/reviews/add/', views.api_add_review_flutter, name='api_add_review_flutter'),
path('api/reviews/<int:review_id>/delete/', views.api_delete_review_flutter, name='api_delete_review_flutter'),
```

## Problem 2: Image URL being converted to base64

This appears to be a behavior of the `pbp_django_auth` package's `post()` method when it detects an image URL.

### Workaround: Use a different field name

In your Django view `api_add_place`, also check for `image_link` as an alternative:

```python
# In api_add_place function, update the image handling:
image_url = request.POST.get('image_url', '') or request.POST.get('image_link', '')

# If it's a base64 string, you might want to handle it differently
if image_url.startswith('data:image'):
    # Either save as-is (works but large) or reject
    # For now, we'll save as-is since it still displays
    pass
```

## After making these changes:

1. Restart Django server
2. Hot reload Flutter app
3. Test adding reviews

The reviews should now work!
