// ===== frontend/lib/widgets/project_card_with_fav.dart =====
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/project_model.dart';
import '../services/api_service.dart';
import '../screens/freelancer/project_details_screen.dart';

class ProjectCardWithFav extends StatefulWidget {
  final Project project;
  final bool showFavoriteButton;
  final VoidCallback? onFavoriteChanged;

  const ProjectCardWithFav({
    super.key,
    required this.project,
    this.showFavoriteButton = true,
    this.onFavoriteChanged,
  });

  @override
  State<ProjectCardWithFav> createState() => _ProjectCardWithFavState();
}

class _ProjectCardWithFavState extends State<ProjectCardWithFav> {
  bool _isFavorite = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    if (!widget.showFavoriteButton) return;

    try {
      final isFav = await ApiService.checkFavorite(widget.project.id!);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
          _checking = false;
        });
      }
    } catch (e) {
      setState(() => _checking = false);
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() => _checking = true);

    try {
      if (_isFavorite) {
        await ApiService.removeFromFavorites(widget.project.id!);
        setState(() => _isFavorite = false);
        Fluttertoast.showToast(msg: 'Removed from favorites');
      } else {
        await ApiService.addToFavorites(widget.project.id!);
        setState(() => _isFavorite = true);
        Fluttertoast.showToast(msg: 'Added to favorites');
      }
      widget.onFavoriteChanged?.call();
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: $e');
    } finally {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ProjectDetailsScreen(projectId: widget.project.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.project.title ?? 'Untitled',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.showFavoriteButton && !_checking)
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: _toggleFavorite,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.project.description ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '\$${widget.project.budget?.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.project.duration} days',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.project.matchScore != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getMatchColor(
                          widget.project.matchScore!,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.project.matchScore}% Match',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _getMatchColor(widget.project.matchScore!),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMatchColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.blue;
  }
}
