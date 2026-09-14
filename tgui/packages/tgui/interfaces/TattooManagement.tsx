import { useState } from 'react';
import {
  Box,
  Button,
  Dropdown,
  Flex,
  Icon,
  Input,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Pigment = {
  name: string;
  color: string;
};

type Zone = {
  key: string;
  name: string;
  sentence_name: string;
  present: boolean;
  count: number;
  intimate: boolean;
};

type Tattoo = {
  zone: string;
  zone_name: string;
  sentence_name: string;
  text: string;
  style: string;
  color: string;
  pigment: string;
  state: number;
  index: number;
};

type Data = {
  tattoos: Tattoo[];
  zones: Zone[];
  pigments: Pigment[];
  max_length: number;
  max_per_zone: number;
};

/** Parchment tone so dark pigments (charcoal, soot) stay readable in preview. */
const PARCHMENT = '#e6dcc0';

const STYLE_LETTERING = 'lettering';
const STYLE_DESIGN = 'design';

/** Renders a tattoo the way it will read on examine. */
/** Lead-in before the inked text, matching what examine prints. */
const previewLead = (style: string, zoneName: string) =>
  style === STYLE_DESIGN
    ? `On the ${zoneName} `
    : `On the ${zoneName} is written: `;

/**
 * The tattoo text itself: dotted underline and a tooltip naming the pigment,
 * mirroring how it renders in chat. Quotes for lettering sit outside the ink.
 */
const InkedText = (props: {
  text: string;
  style: string;
  color: string;
  pigment?: string;
}) => {
  const { text, style, color, pigment } = props;
  const ink = (
    <Box
      as="span"
      title={pigment}
      style={{
        color: color,
        textDecoration: 'underline dotted',
      }}
    >
      {text}
    </Box>
  );
  return style === STYLE_DESIGN ? (
    ink
  ) : (
    <>
      &quot;{ink}&quot;
    </>
  );
};

const AddTattooModal = (props: {
  zones: Zone[];
  pigments: Pigment[];
  maxLength: number;
  maxPerZone: number;
  onCancel: () => void;
  onConfirm: (zone: string, text: string, style: string, color: string) => void;
}) => {
  const { zones, pigments, maxLength, maxPerZone, onCancel, onConfirm } = props;

  const firstOpen = zones.find((z) => z.present && z.count < maxPerZone);
  const [zone, setZone] = useState<string>(
    firstOpen ? firstOpen.key : zones[0]?.key,
  );
  const [text, setText] = useState<string>('');
  const [style, setStyle] = useState<string>(STYLE_LETTERING);
  const [color, setColor] = useState<string>(
    pigments[0]?.color ?? '#2B2B2B',
  );

  const selected = zones.find((z) => z.key === zone);
  const pigment = pigments.find((p) => p.color === color);

  const zoneMissing = selected && !selected.present;
  const zoneFull = selected && selected.count >= maxPerZone;
  const canAdd = !!text.trim() && !zoneMissing && !zoneFull;

  return (
    <Box
      style={{
        position: 'absolute',
        top: '0',
        left: '0',
        right: '0',
        bottom: '0',
        background: 'rgba(0, 0, 0, 0.6)',
        zIndex: '10',
        padding: '18px',
        overflowY: 'auto',
      }}
    >
      <Section
        title="Add a Tattoo"
        buttons={
          <Button icon="xmark" color="transparent" onClick={onCancel}>
            Close
          </Button>
        }
      >
        <Box bold color="label" mb={0.5}>
          Body Zone
        </Box>
        <Dropdown
          width="100%"
          displayText={selected?.name ?? ''}
          selected={selected?.name ?? ''}
          options={zones.map((z) => ({
            displayText: `${z.name}${!z.present ? ' (not present)' : ''}${
              z.present && z.count >= maxPerZone ? ' (full)' : ''
            }`,
            value: z.key,
          }))}
          onSelected={(value) => setZone(value)}
        />
        {!!zoneMissing && (
          <NoticeBox danger mt={1} mb={0}>
            Your character has no {selected?.name} to tattoo.
          </NoticeBox>
        )}
        {!!zoneFull && (
          <NoticeBox warning mt={1} mb={0}>
            There is no room left on the {selected?.name} — {maxPerZone} tattoos
            already.
          </NoticeBox>
        )}

        <Box bold color="label" mt={1.5} mb={0.5}>
          Tattoo Text
        </Box>
        <Input
          fluid
          value={text}
          maxLength={maxLength}
          placeholder={`Enter text (max ${maxLength} characters)`}
          onChange={(value) => setText(value)}
        />
        <Box fontSize="0.85em" color="gray" mt={0.5}>
          {text.length}/{maxLength} characters
        </Box>

        <Box bold color="label" mt={1.5} mb={0.5}>
          Pigment
        </Box>
        <Flex wrap="wrap">
          {pigments.map((p) => (
            <Flex.Item key={p.color} mr={0.5} mb={0.5}>
              <Box
                onClick={() => setColor(p.color)}
                style={{
                  width: '46px',
                  height: '26px',
                  background: p.color,
                  border:
                    p.color === color
                      ? '2px solid #eee69c'
                      : '1px solid #171515',
                  cursor: 'pointer',
                }}
              />
            </Flex.Item>
          ))}
        </Flex>
        <Box fontSize="0.85em" color="gray" mt={0.5}>
          Selected: {pigment?.name ?? 'none'}
        </Box>

        <Box bold color="label" mt={1.5} mb={0.5}>
          Display Style
        </Box>
        <Stack>
          <Stack.Item grow>
            <Button
              fluid
              icon="quote-left"
              selected={style === STYLE_LETTERING}
              onClick={() => setStyle(STYLE_LETTERING)}
            >
              Lettering
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button
              fluid
              icon="image"
              selected={style === STYLE_DESIGN}
              onClick={() => setStyle(STYLE_DESIGN)}
            >
              Description
            </Button>
          </Stack.Item>
        </Stack>
        <Box fontSize="0.85em" color="gray" mt={0.5}>
          {style === STYLE_LETTERING
            ? 'Shown in quotes, as written words.'
            : 'Shown plainly, as a description of a design.'}
        </Box>

        <Box bold color="label" mt={1.5} mb={0.5}>
          Preview
        </Box>
        <Box
          style={{
            background: PARCHMENT,
            border: '1px solid #5b4b40',
            padding: '6px',
            minHeight: '22px',
          }}
        >
          {text.trim() ? (
            <Box style={{ color: '#2f2a21' }}>
              {previewLead(style, selected?.sentence_name ?? '')}
              <InkedText
                text={text}
                style={style}
                color={color}
                pigment={pigment?.name}
              />
            </Box>
          ) : (
            <Box italic style={{ color: '#6b6152' }}>
              Enter text to preview
            </Box>
          )}
        </Box>

        <Stack mt={1.5}>
          <Stack.Item grow>
            <Button fluid icon="xmark" onClick={onCancel}>
              Cancel
            </Button>
          </Stack.Item>
          <Stack.Item grow>
            <Button
              fluid
              icon="plus"
              color="good"
              disabled={!canAdd}
              onClick={() => onConfirm(zone, text.trim(), style, color)}
            >
              Add
            </Button>
          </Stack.Item>
        </Stack>
      </Section>
    </Box>
  );
};

export const TattooManagement = () => {
  const { data, act } = useBackend<Data>();
  const { tattoos = [], zones = [], pigments = [] } = data;
  const [adding, setAdding] = useState(false);

  return (
    <Window width={520} height={640} title="Tattoo Management" theme="vanderlin">
      <Window.Content scrollable>
        <Section
          title="Tattoos"
          buttons={
            <Button
              icon="plus"
              color="good"
              onClick={() => setAdding(true)}
            >
              Add
            </Button>
          }
        >
          <Box color="gray" italic mb={1}>
            Tattoos written here are inked on your character from the start —
            permanent, and only a surgeon can remove them. Only natural
            pigments: soot, ash, ochre, madder and woad.
          </Box>

          {tattoos.length === 0 ? (
            <Flex
              direction="column"
              align="center"
              justify="center"
              style={{ padding: '40px 0' }}
            >
              <Icon name="paint-brush" size={3} color="#5b4b40" />
              <Box mt={1.5} fontSize="1.1em" color="label">
                No tattoos on this character
              </Box>
              <Box mt={0.5} color="gray">
                Press &quot;Add&quot; to ink one
              </Box>
            </Flex>
          ) : (
            tattoos.map((t) => (
              <Section key={`${t.zone}-${t.index}`} mb={0.5}>
                <Stack align="center">
                  <Stack.Item grow>
                    <Box bold color="label">
                      {t.zone_name}
                      {t.state === 2 && (
                        <Box as="span" color="gray" italic ml={1}>
                          (faded)
                        </Box>
                      )}
                    </Box>
                    <Box
                      mt={0.5}
                      style={{
                        background: PARCHMENT,
                        border: '1px solid #5b4b40',
                        padding: '4px 6px',
                        color: '#2f2a21',
                      }}
                    >
                      {previewLead(t.style, t.sentence_name)}
                      <InkedText
                        text={t.text}
                        style={t.style}
                        color={t.color}
                        pigment={t.pigment}
                      />
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="trash"
                      color="bad"
                      tooltip="Remove this tattoo"
                      onClick={() =>
                        act('remove_tattoo', {
                          zone: t.zone,
                          index: t.index,
                        })
                      }
                    />
                  </Stack.Item>
                </Stack>
              </Section>
            ))
          )}
        </Section>

        <NoticeBox info mt={1}>
          Tattoo changes take effect the next time your character spawns.
        </NoticeBox>

        {!!adding && (
          <AddTattooModal
            zones={zones}
            pigments={pigments}
            maxLength={data.max_length}
            maxPerZone={data.max_per_zone}
            onCancel={() => setAdding(false)}
            onConfirm={(zone, text, style, color) => {
              act('add_tattoo', { zone, text, style, color });
              setAdding(false);
            }}
          />
        )}
      </Window.Content>
    </Window>
  );
};
