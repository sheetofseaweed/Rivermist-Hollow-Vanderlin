import {
  Box,
  Button,
  Dropdown,
  Section,
  Stack,
  Tooltip,
} from 'tgui-core/components';
import { useBackend } from '../backend';

type BadgeOption = {
  name: string;
  value: number;
  description: string;
  icon_class: string;
};

type BadgeCategory = {
  id: string;
  name: string;
  description: string;
  multiple: boolean | number;
  value: number;
  label: string;
  icon_class: string | null;
  small_icon_class: string | null;
  options: BadgeOption[];
};

type BadgeData = {
  show: boolean | number;
  overhead: string;
  categories: BadgeCategory[];
};

// Uncomment a category to restore its selector and overhead dropdown option.
// Its saved values, display code and sprites remain available on the backend.
const visibleBadgeCategories = [
  'free_use',
  // 'role',
  // 'scene_access',
  // 'looking_for',
  // 'scene_tone',
  // 'willingness',
  // 'partner',
  'pvp',
  'futa',
];

export const PreferencesBadges = () => {
  const { act, data } = useBackend<{ preference_badges: BadgeData }>();
  const badges = data.preference_badges;
  if (!badges) {
    return null;
  }
  const allCategories = badges.categories ?? [];
  const categories = allCategories.filter((category) =>
    visibleBadgeCategories.includes(category.id),
  );
  // Keep a previously saved overhead selection readable until it is changed.
  const overhead = allCategories.find(
    (category) => category.id === badges.overhead,
  );
  const setValue = (category: string, value: string | number) =>
    act('pref_badge', { task: 'set', category, value });

  return (
    <Section title="Preference Badges">
      <Stack align="center" mb={1}>
        <Stack.Item grow>
          <Box bold>Show Preference Badges</Box>
          <Box color="label">
            Show players&apos; badges above their characters and when examining
            them.
          </Box>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon={badges.show ? 'eye' : 'eye-slash'}
            selected={!!badges.show}
            onClick={() => act('pref_badge', { task: 'toggle_view' })}
          >
            {badges.show ? 'On' : 'Off'}
          </Button>
        </Stack.Item>
      </Stack>
      <Stack align="center" mb={1}>
        <Stack.Item grow>
          <Box bold>Your Overhead Badge</Box>
          <Box color="label">
            Choose one category to display above your character. All enabled
            categories appear when you are examined.
          </Box>
        </Stack.Item>
        {overhead?.small_icon_class ? (
          <Stack.Item>
            <Tooltip content={`${overhead.name}: ${overhead.label}`}>
              <Box className={overhead.small_icon_class} />
            </Tooltip>
          </Stack.Item>
        ) : null}
        <Stack.Item basis="35%">
          <Dropdown
            fluid
            selected={overhead?.name ?? 'None'}
            options={['None', ...categories.map((category) => category.name)]}
            onSelected={(name) =>
              setValue(
                'overhead',
                categories.find((category) => category.name === name)?.id ??
                  'none',
              )
            }
          />
        </Stack.Item>
      </Stack>
      {overhead && !overhead.value ? (
        <Box color="label" mb={1}>
          Enable a {overhead.name} preference below to display its overhead
          badge.
        </Box>
      ) : null}
      <Box color="label" mb={1}>
        Check OOC notes for details about a player&apos;s preferences.
      </Box>
      {categories.map((category) => (
        <Section key={category.id} title={category.name} mb={0.5}>
          <Stack align="center" mb={0.5}>
            {category.icon_class ? (
              <Stack.Item>
                <Tooltip content={category.label}>
                  <Box className={category.icon_class} />
                </Tooltip>
              </Stack.Item>
            ) : null}
            <Stack.Item grow>
              <Box color="label">{category.description}</Box>
            </Stack.Item>
          </Stack>
          {category.multiple ? (
            <Box>
              <Button
                selected={!category.value}
                mr={0.5}
                onClick={() => setValue(category.id, 0)}
              >
                Disabled
              </Button>
              {category.options.map((option) => (
                <Button
                  key={option.value}
                  selected={!!(category.value & option.value)}
                  tooltip={option.description || undefined}
                  mr={0.5}
                  mb={0.5}
                  onClick={() =>
                    setValue(category.id, category.value ^ option.value)
                  }
                >
                  {option.name}
                </Button>
              ))}
            </Box>
          ) : (
            <Dropdown
              fluid
              selected={category.label}
              options={[
                'Disabled',
                ...category.options.map((option) => option.name),
              ]}
              onSelected={(name) =>
                setValue(
                  category.id,
                  category.options.find((option) => option.name === name)
                    ?.value ?? 0,
                )
              }
            />
          )}
          {category.options.find((option) => option.value === category.value)
            ?.description ? (
            <Box color="label" mt={0.5}>
              {
                category.options.find(
                  (option) => option.value === category.value,
                )?.description
              }
            </Box>
          ) : null}
        </Section>
      ))}
    </Section>
  );
};
