import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/provider_model.dart';
import '../../services/api_client.dart';
import '../../providers/provider_provider.dart';

class ProviderDropdown extends StatefulWidget {
  final bool showAllOption;
  final Function(String)? onProviderChanged;

  const ProviderDropdown({
    super.key,
    this.showAllOption = true,
    this.onProviderChanged,
  });

  @override
  State<ProviderDropdown> createState() => _ProviderDropdownState();
}

class _ProviderDropdownState extends State<ProviderDropdown> {
  List<ProviderModel> _providers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProviders();
  }

  Future<void> _fetchProviders() async {
    try {
      final response = await apiClient.get('/users/providers');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        if (mounted) {
          setState(() {
            _providers = data
                .map((json) => ProviderModel.fromJson(json))
                .toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providerState = context.watch<ProviderProvider>();

    if (_isLoading) return _buildLoading(theme);

    return Container(
      height: 40,
      // Quitamos el minWidth/maxWidth rígido para evitar el overflow en pantallas densas
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
          isExpanded:
              false, // Cambiamos a false para que se ajuste al contenido
          elevation: 16,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: theme.colorScheme.surface,
          menuMaxHeight: 350,
          // Esto evita que el menú se dibuje sobre el botón
          alignment: AlignmentDirectional.center,
          selectedItemBuilder: (BuildContext context) {
            return [
              if (widget.showAllOption) _buildCompactItem('Todos'),
              ..._providers.map((prov) => _buildCompactItem(prov.tag)),
            ];
          },
          items: [
            if (widget.showAllOption)
              DropdownMenuItem(
                value: 'all',
                child: _buildExpandedItem(theme, 'ALL', 'Ver todos', true),
              ),
            ..._providers.map((prov) {
              return DropdownMenuItem(
                value: prov.id,
                child: _buildExpandedItem(theme, prov.tag, prov.name, false),
              );
            }),
          ],
          onChanged: (String? newValue) {
            if (newValue != null) {
              providerState.setProvider(newValue);
              if (widget.onProviderChanged != null) {
                widget.onProviderChanged!(newValue);
              }
            }
          },
        ),
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

  // VISTA COMPACTA (La que sale en el AppBar)
  Widget _buildCompactItem(String text) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min, // Súper importante
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
        const SizedBox(width: 4), // Espacio antes de la flechita
      ],
    );
  }

  // VISTA DESPLEGADA (La lista al abrir)
  Widget _buildExpandedItem(
    ThemeData theme,
    String tag,
    String name,
    bool isAllOption,
  ) {
    return SizedBox(
      width: 200, // Ancho fijo para que la lista se vea uniforme
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
