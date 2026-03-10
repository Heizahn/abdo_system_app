import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/provider_model.dart';
import '../../services/api_client.dart';
import '../../providers/provider_provider.dart';
import '../query_builder.dart';

class ProviderDropdown extends StatelessWidget {
  final bool showAllOption;
  final Function(String)? onProviderChanged;

  const ProviderDropdown({
    super.key,
    this.showAllOption = true,
    this.onProviderChanged,
  });

  static const _queryKey = 'providers:list';

  static Future<List<ProviderModel>> _fetchProviders() async {
    final response = await apiClient.get('/users/providers');
    final List<dynamic> data = response.data;
    return data.map((json) => ProviderModel.fromJson(json)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return QueryBuilder<List<ProviderModel>>(
      queryKey: _queryKey,
      queryFn: _fetchProviders,
      // La lista de proveedores casi nunca cambia, cache largo
      staleTime: const Duration(minutes: 10),
      loading: _buildLoading(Theme.of(context)),
      builder: (context, providers, isRefreshing) => _DropdownContent(
        providers: providers,
        showAllOption: showAllOption,
        onProviderChanged: onProviderChanged,
      ),
    );
  }

  Widget _buildLoading(ThemeData theme) {
    return Container(
      height: 40,
      width: 120,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class _DropdownContent extends StatelessWidget {
  final List<ProviderModel> providers;
  final bool showAllOption;
  final Function(String)? onProviderChanged;

  const _DropdownContent({
    required this.providers,
    required this.showAllOption,
    this.onProviderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providerState = context.watch<ProviderProvider>();

    return Container(
      height: 40,
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: providerState.selectedProviderId,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 22,
            color: theme.colorScheme.primary,
          ),
          isExpanded: false,
          elevation: 16,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: theme.colorScheme.surface,
          menuMaxHeight: 350,
          alignment: AlignmentDirectional.center,
          selectedItemBuilder: (BuildContext context) {
            return [
              if (showAllOption) _buildCompactItem(theme, 'Todos'),
              ...providers.map((prov) => _buildCompactItem(theme, prov.tag)),
            ];
          },
          items: [
            if (showAllOption)
              DropdownMenuItem(
                value: 'all',
                child: _buildExpandedItem(theme, 'ALL', 'Ver todos', true),
              ),
            ...providers.map((prov) {
              return DropdownMenuItem(
                value: prov.id,
                child: _buildExpandedItem(theme, prov.tag, prov.name, false),
              );
            }),
          ],
          onChanged: (String? newValue) {
            if (newValue != null) {
              providerState.setProvider(newValue);
              onProviderChanged?.call(newValue);
            }
          },
        ),
      ),
    );
  }

  Widget _buildCompactItem(ThemeData theme, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.storefront_outlined,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildExpandedItem(
    ThemeData theme,
    String tag,
    String name,
    bool isAllOption,
  ) {
    return SizedBox(
      width: 200,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isAllOption
                  ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.1)
                  : theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isAllOption
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isAllOption)
                  Text(
                    'Proveedor',
                    style: TextStyle(
                      fontSize: 9,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
