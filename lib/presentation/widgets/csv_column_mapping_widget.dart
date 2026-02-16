import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Widget for manually mapping CSV columns to transaction fields.
class CsvColumnMappingWidget extends StatefulWidget {
  final List<String> headers;
  final List<List<dynamic>> sampleRows;
  final Map<String, int?> initialMapping;
  final Function(Map<String, int?>) onMappingChanged;

  const CsvColumnMappingWidget({
    super.key,
    required this.headers,
    required this.sampleRows,
    required this.initialMapping,
    required this.onMappingChanged,
  });

  @override
  State<CsvColumnMappingWidget> createState() => _CsvColumnMappingWidgetState();
}

class _CsvColumnMappingWidgetState extends State<CsvColumnMappingWidget> {
  late Map<String, int?> _mapping;

  @override
  void initState() {
    super.initState();
    _mapping = Map.from(widget.initialMapping);
  }

  void _updateMapping(String field, int? columnIndex) {
    setState(() {
      _mapping[field] = columnIndex;
    });
    widget.onMappingChanged(_mapping);
  }

  Widget _buildMappingRow(
    String fieldName,
    String fieldKey,
    IconData icon,
    bool required,
  ) {
    final theme = Theme.of(context);
    final selectedColumn = _mapping[fieldKey];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Field icon and name
          SizedBox(
            width: 180,
            child: Row(
              children: [
                FaIcon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    fieldName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (required)
                  Text(
                    '*',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Column dropdown
          Expanded(
            child: DropdownButtonFormField<int?>(
              value: selectedColumn,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    required ? 'Select column...' : 'None',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                ...widget.headers.asMap().entries.map((entry) {
                  return DropdownMenuItem<int?>(
                    value: entry.key,
                    child: Text('${entry.key + 1}. ${entry.value}'),
                  );
                }),
              ],
              onChanged: (value) => _updateMapping(fieldKey, value),
            ),
          ),

          const SizedBox(width: 16),

          // Sample preview
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Text(
                selectedColumn != null && widget.sampleRows.isNotEmpty
                    ? _getSampleValue(selectedColumn)
                    : 'No preview',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSampleValue(int columnIndex) {
    if (widget.sampleRows.isEmpty) return '';
    
    final samples = widget.sampleRows
        .take(3)
        .map((row) {
          if (columnIndex >= row.length) return '';
          return row[columnIndex]?.toString() ?? '';
        })
        .where((s) => s.isNotEmpty)
        .take(2)
        .join(', ');
    
    return samples.isEmpty ? 'Empty' : samples;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            FaIcon(
              FontAwesomeIcons.tableCells,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'Map CSV Columns to Fields',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Match your CSV columns to the transaction fields below. Required fields are marked with *',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),

        // Column headers
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 180,
                child: Text(
                  'Transaction Field',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'CSV Column',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: Text(
                  'Sample Values',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        ),

        const Divider(),

        // Required fields
        _buildMappingRow(
          'Date',
          'date',
          FontAwesomeIcons.calendar,
          true,
        ),
        _buildMappingRow(
          'Description',
          'description',
          FontAwesomeIcons.fileLines,
          true,
        ),

        const SizedBox(height: 16),
        Text(
          'Amount Fields (choose one option)',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        
        _buildMappingRow(
          'Single Amount',
          'amount',
          FontAwesomeIcons.dollarSign,
          false,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Text(
            'OR',
            style: theme.textTheme.labelSmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
        _buildMappingRow(
          'Debit/Withdrawal',
          'debit',
          FontAwesomeIcons.arrowUp,
          false,
        ),
        _buildMappingRow(
          'Credit/Deposit',
          'credit',
          FontAwesomeIcons.arrowDown,
          false,
        ),

        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),

        // Optional fields
        Text(
          'Optional Fields',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        
        _buildMappingRow(
          'Category',
          'category',
          FontAwesomeIcons.tag,
          false,
        ),
        _buildMappingRow(
          'Notes',
          'notes',
          FontAwesomeIcons.noteSticky,
          false,
        ),

        const SizedBox(height: 24),

        // Validation message
        if (_mapping['date'] == null || _mapping['description'] == null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.triangleExclamation,
                  size: 16,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please map required fields: Date and Description',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),

        if (_mapping['amount'] == null &&
            (_mapping['debit'] == null || _mapping['credit'] == null))
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.triangleExclamation,
                  size: 16,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Please map either Amount OR both Debit and Credit columns',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
