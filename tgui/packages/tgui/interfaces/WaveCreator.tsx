import {
  Box,
  Button,
  Dropdown,
  Input,
  NumberInput,
  Section,
  Stack,
  Table,
} from 'tgui-core/components';
import { useBackend, useLocalState } from '../backend';
import { Window } from '../layouts';

type Waypoint = {
  ref: string;
  order: number;
  name: string;
  coordinates: string;
};

type MobEntry = {
  path: string;
  name: string;
  count: number;
};

type MobType = {
  path: string;
  name: string;
};

type Data = {
  set_id: string;
  waypoints: Waypoint[];
  mob_entries: MobEntry[];
  living_subtypes: MobType[];
};

export const WaveCreator = () => {
  const { act, data } = useBackend<Data>();
  const {
    set_id,
    waypoints = [],
    mob_entries = [],
    living_subtypes = [],
  } = data;

  const [editingSetId, setEditingSetId] = useLocalState('editingSetId', false);
  const [setIdDraft, setSetIdDraft] = useLocalState('setIdDraft', set_id);
  const [selectedPath, setSelectedPath] = useLocalState(
    'selectedPath',
    living_subtypes[0]?.path ?? '',
  );

  const mobOptions = living_subtypes.map((mob) => ({
    displayText: `${mob.name} — ${mob.path}`,
    value: mob.path,
  }));
  const selectedMob = mobOptions.find(
    (option) => option.value === selectedPath,
  );
  const hasConfiguredMobs = mob_entries.some((entry) => entry.count > 0);

  const saveSetId = () => {
    act('set_set_id', { set_id: setIdDraft });
    setEditingSetId(false);
  };

  return (
    <Window width={700} height={620} title="Wave Creator">
      <Window.Content scrollable>
        <Section title="Wave Set">
          <Stack align="center">
            <Stack.Item color="label">Set ID:</Stack.Item>
            <Stack.Item grow>
              {editingSetId ? (
                <Input
                  fluid
                  maxLength={64}
                  value={setIdDraft}
                  onChange={setSetIdDraft}
                  onEnter={saveSetId}
                />
              ) : (
                <Box bold>{set_id}</Box>
              )}
            </Stack.Item>
            <Stack.Item>
              {editingSetId ? (
                <Button icon="check" color="good" onClick={saveSetId} />
              ) : (
                <Button
                  icon="pencil-alt"
                  onClick={() => {
                    setSetIdDraft(set_id);
                    setEditingSetId(true);
                  }}
                />
              )}
            </Stack.Item>
            <Stack.Item>
              <Button.Confirm
                icon="play"
                color="good"
                disabled={!waypoints.length || !hasConfiguredMobs}
                confirmContent="Launch?"
                onClick={() => act('launch_wave')}
              >
                Launch Wave
              </Button.Confirm>
            </Stack.Item>
          </Stack>
        </Section>

        <Section
          title={`Waypoints (${waypoints.length})`}
          buttons={
            <Button
              icon="plus"
              color="good"
              onClick={() => act('add_waypoint')}
            >
              Place at Feet
            </Button>
          }
        >
          {waypoints.length === 0 ? (
            <Box color="label" italic>
              No landmarks for set &quot;{set_id}&quot;.
            </Box>
          ) : (
            <Stack vertical>
              {waypoints.map((waypoint) => (
                <Stack.Item key={waypoint.ref}>
                  <Stack align="center">
                    <Stack.Item color="label" width="2rem" textAlign="center">
                      #{waypoint.order}
                    </Stack.Item>
                    <Stack.Item grow>
                      {waypoint.name} {waypoint.coordinates}
                    </Stack.Item>
                    <Stack.Item>
                      <Button.Confirm
                        icon="trash"
                        color="bad"
                        confirmContent="Remove?"
                        onClick={() =>
                          act('remove_waypoint', { ref: waypoint.ref })
                        }
                      />
                    </Stack.Item>
                  </Stack>
                </Stack.Item>
              ))}
            </Stack>
          )}
        </Section>

        <Section title="Wave Mobs">
          <Stack align="center" mb={1}>
            <Stack.Item grow>
              <Dropdown
                fluid
                displayText={selectedMob?.displayText ?? 'Select an AI mob'}
                selected={selectedMob ?? null}
                options={mobOptions}
                onSelected={setSelectedPath}
              />
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="plus"
                disabled={!selectedPath}
                onClick={() => {
                  const existing = mob_entries.find(
                    (entry) => entry.path === selectedPath,
                  );
                  act('set_mob_count', {
                    path: selectedPath,
                    count: (existing?.count ?? 0) + 1,
                  });
                }}
              >
                Add
              </Button>
            </Stack.Item>
          </Stack>

          {hasConfiguredMobs ? (
            <Table>
              <Table.Row header>
                <Table.Cell>Mob</Table.Cell>
                <Table.Cell collapsing>Count</Table.Cell>
                <Table.Cell collapsing />
              </Table.Row>
              {mob_entries
                .filter((entry) => entry.count > 0)
                .map((entry) => (
                  <Table.Row key={entry.path}>
                    <Table.Cell>
                      <Box>{entry.name}</Box>
                      <Box color="label" fontSize="10px">
                        {entry.path}
                      </Box>
                    </Table.Cell>
                    <Table.Cell collapsing>
                      <NumberInput
                        width="60px"
                        minValue={1}
                        maxValue={50}
                        step={1}
                        value={entry.count}
                        onChange={(count) =>
                          act('set_mob_count', { path: entry.path, count })
                        }
                      />
                    </Table.Cell>
                    <Table.Cell collapsing>
                      <Button
                        icon="times"
                        color="bad"
                        onClick={() =>
                          act('set_mob_count', {
                            path: entry.path,
                            count: 0,
                          })
                        }
                      />
                    </Table.Cell>
                  </Table.Row>
                ))}
            </Table>
          ) : (
            <Box color="label" italic>
              No mobs configured.
            </Box>
          )}
        </Section>
      </Window.Content>
    </Window>
  );
};
