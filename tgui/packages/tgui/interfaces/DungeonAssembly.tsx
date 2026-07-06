import { useBackend } from '../backend';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';
import { Window } from '../layouts';

type RosterRow = {
  name: string;
  rank: string | null;
  ready: 0 | 1;
  leader: 0 | 1;
};

type HeatDial = {
  id: string;
  name: string;
  desc: string;
  rank: number;
  max_rank: number;
};

type Data = {
  has_party: 0 | 1;
  party_name: string | null;
  leader_name: string | null;
  is_leader: 0 | 1;
  run_active: 0 | 1;
  dormant: 0 | 1;
  roster: RosterRow[];
  echoes: number;
  covenant_owned: 0 | 1;
  heat_locked: 0 | 1;
  dials: HeatDial[];
  total_heat: number;
  echo_bonus_percent: number;
};

export function DungeonAssembly(props) {
  const { act, data } = useBackend<Data>();
  const {
    has_party,
    party_name,
    leader_name,
    is_leader,
    run_active,
    dormant,
    roster = [],
    echoes,
    covenant_owned,
    heat_locked,
    dials = [],
    total_heat,
    echo_bonus_percent,
  } = data;

  return (
    <Window title="Assemble the Expedition" width={420} height={460}>
      <Window.Content scrollable>
        <Stack fill vertical>
          {!!dormant && (
            <Stack.Item>
              <NoticeBox danger>
                The way down is buried under fresh rubble. It has not reopened
                yet.
              </NoticeBox>
            </Stack.Item>
          )}
          {!!run_active && (
            <Stack.Item>
              <NoticeBox info>
                An expedition is already underway below. Members may descend to
                rejoin it.
              </NoticeBox>
            </Stack.Item>
          )}
          <Stack.Item>
            <Section title="The Ledger">
              <LabeledList>
                <LabeledList.Item label="Your Echoes" color="teal">
                  {echoes}
                </LabeledList.Item>
              </LabeledList>
            </Section>
          </Stack.Item>
          {!!covenant_owned && (
            <Stack.Item>
              <Section
                title="The Grim Covenant"
                buttons={
                  <Box inline color="purple" bold>
                    Heat {total_heat} · +{echo_bonus_percent}% echoes
                  </Box>
                }
              >
                {heat_locked ? (
                  <NoticeBox info>
                    The pact is sealed for the run underway.
                  </NoticeBox>
                ) : (
                  dials.map((dial) => (
                    <Box key={dial.id} mb={0.5}>
                      <Box inline width="55%">
                        <Box bold>{dial.name}</Box>
                        <Box color="label" fontSize="0.85em">
                          {dial.desc}
                        </Box>
                      </Box>
                      <Box inline width="45%" textAlign="right" verticalAlign="top">
                        {[...Array(dial.max_rank + 1).keys()].map((r) => (
                          <Button
                            key={r}
                            selected={dial.rank === r}
                            onClick={() =>
                              act('set_dial', { id: dial.id, rank: r })
                            }
                          >
                            {r}
                          </Button>
                        ))}
                      </Box>
                    </Box>
                  ))
                )}
              </Section>
            </Stack.Item>
          )}
          <Stack.Item grow>
            {has_party ? (
              <Section
                fill
                title={party_name || 'The Party'}
                buttons={
                  <Button icon="user-plus" onClick={() => act('invite')}>
                    Invite
                  </Button>
                }
              >
                <LabeledList>
                  <LabeledList.Item label="Leader">
                    {leader_name || '—'}
                  </LabeledList.Item>
                </LabeledList>
                <Box mt={1}>
                  {roster.map((row) => (
                    <Box key={row.name}>
                      <Box inline color={row.ready ? 'good' : 'bad'}>
                        {row.ready ? '●' : '○'}
                      </Box>{' '}
                      <Box inline bold={!!row.leader}>
                        {row.name}
                      </Box>{' '}
                      {row.rank && (
                        <Box inline color="label">
                          — {row.rank}
                        </Box>
                      )}
                      <Box inline color="label" ml={0.5}>
                        ({row.ready ? 'at the mouth' : 'away'})
                      </Box>
                    </Box>
                  ))}
                </Box>
              </Section>
            ) : (
              <Section fill title="No Party">
                <Box color="label" mb={1}>
                  You need a party to mount an expedition.
                </Box>
                <Button fluid icon="users" onClick={() => act('create_party')}>
                  Form an Expedition
                </Button>
              </Section>
            )}
          </Stack.Item>
          {!!has_party && (
            <Stack.Item>
              <Button
                fluid
                icon="dungeon"
                color="good"
                disabled={!is_leader || !!dormant}
                tooltip={
                  !is_leader
                    ? 'Only the leader gives the order to descend.'
                    : undefined
                }
                onClick={() => act('descend')}
              >
                Descend
              </Button>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
}
