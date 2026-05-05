import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import 'neumorphic_card.dart';
import '../../features/employees/employee_provider.dart';

class EmployeeTile extends StatelessWidget {
  final Employee employee;
  final String departmentName;
  final String? authToken;
  final Widget? trailing;

  const EmployeeTile({
    super.key,
    required this.employee,
    required this.departmentName,
    this.authToken,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicCard(
      padding: const EdgeInsets.all(8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          child: NeumorphicCard(
            padding: EdgeInsets.zero,
            borderRadius: 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: employee.photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: employee.photoUrl!,
                      httpHeaders: authToken != null
                          ? {
                              'Authorization': 'Bearer $authToken',
                            }
                          : null,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => _buildPlaceholder(employee.name),
                    )
                  : _buildPlaceholder(employee.name),
            ),
          ),
        ),
        title: Text(
          employee.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (employee.email != null && employee.email!.isNotEmpty)
              Text(
                employee.email!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            Text(
              departmentName,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildPlaceholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}
