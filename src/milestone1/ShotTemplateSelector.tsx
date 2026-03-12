import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';

import { SHOT_TEMPLATES, type ShotTemplateId } from '../config/shotTemplates';

type ShotTemplateSelectorProps = {
  onSelect: (templateId: ShotTemplateId) => void;
  selectedTemplateId: ShotTemplateId;
};

export function ShotTemplateSelector({
  onSelect,
  selectedTemplateId,
}: ShotTemplateSelectorProps) {
  return (
    <View style={styles.container}>
      <Text style={styles.label}>Shot type</Text>
      <ScrollView
        contentContainerStyle={styles.content}
        horizontal
        showsHorizontalScrollIndicator={false}
      >
        {SHOT_TEMPLATES.map((template) => {
          const selected = template.id === selectedTemplateId;

          return (
            <Pressable
              key={template.id}
              onPress={() => onSelect(template.id)}
              style={[styles.chip, selected ? styles.chipSelected : null]}
            >
              <Text style={[styles.chipTitle, selected ? styles.chipTitleSelected : null]}>
                {template.label}
              </Text>
              <Text style={[styles.chipSummary, selected ? styles.chipSummarySelected : null]}>
                {template.summary}
              </Text>
            </Pressable>
          );
        })}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  chip: {
    backgroundColor: '#101b2d',
    borderColor: '#1d2a40',
    borderRadius: 18,
    borderWidth: 1,
    gap: 6,
    marginRight: 12,
    paddingHorizontal: 14,
    paddingVertical: 12,
    width: 170,
  },
  chipSelected: {
    backgroundColor: '#effd95',
    borderColor: '#effd95',
  },
  chipSummary: {
    color: '#94a7c2',
    fontSize: 12,
    lineHeight: 17,
  },
  chipSummarySelected: {
    color: '#31431b',
  },
  chipTitle: {
    color: '#ffffff',
    fontSize: 14,
    fontWeight: '700',
  },
  chipTitleSelected: {
    color: '#11190d',
  },
  container: {
    gap: 10,
  },
  content: {
    paddingRight: 12,
  },
  label: {
    color: '#8ea0b8',
    fontSize: 12,
    fontWeight: '700',
    letterSpacing: 1.2,
    textTransform: 'uppercase',
  },
});
