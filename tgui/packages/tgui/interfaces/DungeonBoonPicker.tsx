import { useBackend } from '../backend';
import { Box, Button, Section, Stack } from 'tgui-core/components';
import { Window } from '../layouts';

type BoonCard = {
  name: string;
  god: string | null;
  rarity: 'common' | 'rare' | 'epic';
  desc: string;
  domains: string[];
  synergy: 0 | 1;
};

type Data = {
  cards: BoonCard[];
};

const RARITY_COLOR = {
  common: 'label',
  rare: 'blue',
  epic: 'purple',
};

export function DungeonBoonPicker(props) {
  const { act, data } = useBackend<Data>();
  const { cards = [] } = data;

  return (
    <Window title="A Blessing Is Offered" width={640} height={360}>
      <Window.Content>
        <Stack fill>
          {cards.map((card, i) => (
            <Stack.Item key={i} grow basis={0}>
              <Section
                fill
                title={
                  <Box inline color={RARITY_COLOR[card.rarity]}>
                    {card.rarity.toUpperCase()}
                    {!!card.synergy && ' • SYNERGY'}
                  </Box>
                }
              >
                <Stack fill vertical>
                  {card.god && (
                    <Stack.Item>
                      <Box color="gold" italic>
                        {card.god}
                      </Box>
                    </Stack.Item>
                  )}
                  <Stack.Item>
                    <Box bold fontSize="1.1em">
                      {card.name}
                    </Box>
                  </Stack.Item>
                  <Stack.Item grow>
                    <Box color="label">{card.desc}</Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Box color="average" fontSize="0.9em">
                      {card.domains.join(' • ')}
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      fluid
                      icon="hand-sparkles"
                      color={card.rarity === 'epic' ? 'purple' : 'default'}
                      onClick={() => act('pick', { index: i + 1 })}
                    >
                      Accept
                    </Button>
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>
          ))}
        </Stack>
      </Window.Content>
    </Window>
  );
}
