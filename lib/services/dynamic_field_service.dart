import '../models/dynamic_field_config.dart';
import '../models/database_complaint_model.dart';

class DynamicFieldService {
  // Get visible fields for a selected crime type
  static List<ComplaintField> getVisibleFields(DatabaseCrimeType? selectedCrimeType) {
    if (selectedCrimeType == null) {
      // Return only core fields if no crime type selected
      return [
        ComplaintField.crimeType,
        ComplaintField.description,
        ComplaintField.incidentDateTime,
        ComplaintField.fullName,
        ComplaintField.email,
        ComplaintField.phone,
        ComplaintField.evidenceFiles,
      ];
    }

    return DynamicFieldConfig.getFieldsForCategory(selectedCrimeType.categoryForFields);
  }

  // Check if a specific field should be visible
  static bool isFieldVisible(ComplaintField field, DatabaseCrimeType? selectedCrimeType) {
    if (selectedCrimeType == null) {
      // Only core fields visible when no crime type selected
      return _coreFields.contains(field);
    }

    return DynamicFieldConfig.isFieldVisible(field, selectedCrimeType.categoryForFields);
  }

  // Get field configuration for UI rendering
  static FieldConfiguration? getFieldConfig(ComplaintField field) {
    return DynamicFieldConfig.getFieldConfig(field);
  }

  // Get all fields that were visible in the previous state
  static List<ComplaintField> getPreviouslyVisibleFields(DatabaseCrimeType? previousCrimeType) {
    if (previousCrimeType == null) return _coreFields;
    return getVisibleFields(previousCrimeType);
  }

  // Get fields that should be cleared when switching crime types
  static List<ComplaintField> getFieldsToClear(
    DatabaseCrimeType? previousCrimeType, 
    DatabaseCrimeType? newCrimeType
  ) {
    final previousFields = getPreviouslyVisibleFields(previousCrimeType);
    final newFields = getVisibleFields(newCrimeType);
    
    // Return fields that were visible before but not now
    return previousFields.where((field) => !newFields.contains(field)).toList();
  }

  // Get fields that are newly visible
  static List<ComplaintField> getNewlyVisibleFields(
    DatabaseCrimeType? previousCrimeType, 
    DatabaseCrimeType? newCrimeType
  ) {
    final previousFields = getPreviouslyVisibleFields(previousCrimeType);
    final newFields = getVisibleFields(newCrimeType);
    
    // Return fields that are visible now but weren't before
    return newFields.where((field) => !previousFields.contains(field)).toList();
  }

  // Check if crime type change requires form state updates
  static bool requiresFormUpdate(DatabaseCrimeType? previousCrimeType, DatabaseCrimeType? newCrimeType) {
    if (previousCrimeType == null && newCrimeType == null) return false;
    if (previousCrimeType == null || newCrimeType == null) return true;
    
    // Check if the categories are different
    return previousCrimeType.categoryForFields != newCrimeType.categoryForFields;
  }

  // Get field label for UI
  static String getFieldLabel(ComplaintField field) {
    final config = getFieldConfig(field);
    if (config != null) return config.label;
    
    // Fallback labels for core fields
    switch (field) {
      case ComplaintField.crimeType:
        return 'Crime Type';
      case ComplaintField.officer:
        return 'Preferred Officer';
      case ComplaintField.description:
        return 'Description of Incident';
      case ComplaintField.incidentDateTime:
        return 'Date and Time of Incident';
      case ComplaintField.fullName:
        return 'Full Name';
      case ComplaintField.email:
        return 'Email Address';
      case ComplaintField.phone:
        return 'Phone Number';
      case ComplaintField.evidenceFiles:
        return 'Evidence Files';
      default:
        return field.name;
    }
  }

  // Get field hint/placeholder
  static String? getFieldHint(ComplaintField field) {
    final config = getFieldConfig(field);
    return config?.hint;
  }

  // Get field description for help text
  static String? getFieldDescription(ComplaintField field) {
    final config = getFieldConfig(field);
    return config?.description;
  }

  // Check if field is required
  static bool isFieldRequired(ComplaintField field) {
    final config = getFieldConfig(field);
    if (config != null) return config.isRequired;
    
    // Core fields that are always required
    switch (field) {
      case ComplaintField.crimeType:
      case ComplaintField.description:
      case ComplaintField.incidentDateTime:
      case ComplaintField.fullName:
      case ComplaintField.email:
      case ComplaintField.phone:
        return true;
      default:
        return false;
    }
  }

  // Get validation error message for a field
  static String? getValidationError(ComplaintField field, String? value) {
    if (isFieldRequired(field) && (value == null || value.trim().isEmpty)) {
      return '${getFieldLabel(field)} is required';
    }

    // Field-specific validation
    switch (field) {
      case ComplaintField.email:
        if (value != null && value.isNotEmpty) {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(value)) {
            return 'Please enter a valid email address';
          }
        }
        break;
      case ComplaintField.phone:
        if (value != null && value.isNotEmpty) {
          final phoneRegex = RegExp(r'^[\+]?[\d\s\-\(\)]{7,}$');
          if (!phoneRegex.hasMatch(value)) {
            return 'Please enter a valid phone number';
          }
        }
        break;
      case ComplaintField.description:
        if (value != null && value.length < 20) {
          return 'Description must be at least 20 characters';
        }
        break;
      case ComplaintField.financialLoss:
        if (value != null && value.isNotEmpty) {
          final amount = double.tryParse(value);
          if (amount == null || amount < 0) {
            return 'Please enter a valid amount';
          }
        }
        break;
      default:
        break;
    }

    return null;
  }

  // Core fields that are always visible
  static const List<ComplaintField> _coreFields = [
    ComplaintField.crimeType,
    ComplaintField.description,
    ComplaintField.incidentDateTime,
    ComplaintField.fullName,
    ComplaintField.email,
    ComplaintField.phone,
    ComplaintField.evidenceFiles,
  ];
}