//RMH EDITED - new file: TGUI "Ducal Court" interface for the throne, wrapping
//the TITAN command hub (/obj/structure/fake_machine/titan). Voice commands keep
//working; this is a parallel, button-driven path with the same permission gates.
import type { CSSProperties } from 'react';
import type { ReactNode } from 'react';
import { useState } from 'react';
import type { BooleanLike } from 'tgui-core/react';

import { DmIcon } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type ThroneData = {
  wearing_crown: BooleanLike;
  is_ruler: BooleanLike;
  is_regent: BooleanLike;
  worthy: BooleanLike;
  cooldown_ok: BooleanLike;
  can_command: BooleanLike;
  can_announce: BooleanLike;
  ruler_name: string;
  regent_name: string;
  tax_percent: number;
  lord_primary: string | null;
  lord_secondary: string | null;
  flag_icon: string;
  flag_state: string;
  laws: string[];
  decrees: string[];
  outlaws: string[];
};

type ActFn = (action: string, params?: Record<string, unknown>) => void;

// --- Dark royal palette (matches the Azure court screenshot) ---------------
const SERIF = '"Lora", Georgia, serif';
const BG = '#15100b';
const PANEL = 'linear-gradient(180deg, #2a2018 0%, #1c1510 100%)';
const PANEL_FLAT = '#221a12';
const CARD = 'linear-gradient(180deg, #3a2c1d 0%, #241a11 100%)';
const GOLD = '#d8b96a';
const GOLD_DIM = '#9c855450';
const GOLD_SOFT = '#b89a5a';
const INK = '#e8dcc2';
const INK_SOFT = '#b9a884';
const GREEN = '#5f8c52';
const RED = '#a8433a';
const BORDER = '#5a4528';

const pageStyle: CSSProperties = {
  minHeight: '100%',
  background: BG,
  color: INK,
  fontFamily: SERIF,
  fontSize: '13px',
  padding: '0 0 18px 0',
};

const headerStyle: CSSProperties = {
  background: PANEL,
  borderBottom: `2px solid ${BORDER}`,
  padding: '12px 24px',
  display: 'flex',
  alignItems: 'center',
  justifyContent: 'space-between',
};

const titleStyle: CSSProperties = {
  fontSize: '26px',
  fontWeight: 'bold',
  color: GOLD,
  letterSpacing: '1px',
  fontFamily: '"MedievalSharp", Georgia, serif',
};

const tabBarStyle: CSSProperties = {
  display: 'flex',
  gap: '6px',
  padding: '12px 24px 0 24px',
};

const tabStyle = (active: boolean): CSSProperties => ({
  fontFamily: SERIF,
  fontSize: '13px',
  padding: '6px 16px',
  color: active ? '#1a1209' : GOLD,
  background: active ? GOLD : 'transparent',
  border: `1px solid ${active ? GOLD : BORDER}`,
  borderBottom: active ? `1px solid ${GOLD}` : `1px solid ${BORDER}`,
  borderRadius: '3px 3px 0 0',
  cursor: 'pointer',
  fontWeight: active ? 'bold' : 'normal',
});

const sectionStyle: CSSProperties = {
  margin: '14px 24px',
  background: PANEL_FLAT,
  border: `1px solid ${BORDER}`,
  borderRadius: '4px',
};

const sectionTitleStyle: CSSProperties = {
  background: PANEL,
  borderBottom: `1px solid ${BORDER}`,
  padding: '8px 14px',
  color: GOLD,
  fontWeight: 'bold',
  textTransform: 'uppercase',
  letterSpacing: '1px',
  fontSize: '13px',
};

const sectionBodyStyle: CSSProperties = { padding: '12px 14px' };

const cardStyle: CSSProperties = {
  background: CARD,
  border: `1px solid ${BORDER}`,
  borderRadius: '3px',
  padding: '10px 12px',
};

const btn = (opts: { disabled?: boolean; tone?: 'gold' | 'green' | 'red' } = {}): CSSProperties => {
  const tone = opts.tone || 'gold';
  const col = tone === 'green' ? GREEN : tone === 'red' ? RED : GOLD;
  return {
    fontFamily: SERIF,
    fontSize: '13px',
    fontWeight: 'bold',
    padding: '4px 14px',
    color: opts.disabled ? INK_SOFT : '#1a1209',
    background: opts.disabled ? 'transparent' : col,
    border: `1px solid ${opts.disabled ? GOLD_DIM : col}`,
    borderRadius: '3px',
    cursor: opts.disabled ? 'default' : 'pointer',
    opacity: opts.disabled ? 0.55 : 1,
    whiteSpace: 'nowrap',
  };
};

const inputStyle: CSSProperties = {
  width: '100%',
  boxSizing: 'border-box',
  background: '#100c08',
  border: `1px solid ${BORDER}`,
  borderRadius: '3px',
  color: INK,
  fontFamily: SERIF,
  fontSize: '13px',
  padding: '6px 8px',
  outline: 'none',
};

// --- Small pieces ----------------------------------------------------------
const StatusCard = (props: { label: string; value: string; tone?: string }) => (
  <div style={{ ...cardStyle, flex: 1, minWidth: '150px' }}>
    <div style={{ color: INK_SOFT, fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.5px' }}>
      {props.label}
    </div>
    <div style={{ color: props.tone || GOLD, fontWeight: 'bold', fontSize: '16px' }}>{props.value}</div>
  </div>
);

const Section = (props: { title: string; children: ReactNode }) => (
  <div style={sectionStyle}>
    <div style={sectionTitleStyle}>{props.title}</div>
    <div style={sectionBodyStyle}>{props.children}</div>
  </div>
);

// A labelled colour chip for the heraldry preview.
const Swatch = (props: { label: string; color: string | null }) => (
  <div style={{ textAlign: 'center' }}>
    <div
      style={{
        width: '34px',
        height: '34px',
        borderRadius: '3px',
        border: `1px solid ${BORDER}`,
        background: props.color || 'repeating-linear-gradient(45deg, #2a2018, #2a2018 4px, #181109 4px, #181109 8px)',
      }}
    />
    <div style={{ color: INK_SOFT, fontSize: '11px', marginTop: '2px' }}>
      {props.label}
      {!props.color && <span style={{ display: 'block', color: GOLD_SOFT }}>unset</span>}
    </div>
  </div>
);

// --- Tabs ------------------------------------------------------------------
const Overview = (props: { data: ThroneData }) => {
  const { data } = props;
  return (
    <Section title="Court Standing">
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '10px' }}>
        <StatusCard label="Current Ruler" value={data.ruler_name} />
        <StatusCard label="Regent" value={data.regent_name} tone={data.regent_name === 'None' ? INK_SOFT : GOLD} />
        <StatusCard
          label="Your Crown"
          value={data.wearing_crown ? 'Worn' : 'Absent'}
          tone={data.wearing_crown ? GREEN : RED}
        />
        <StatusCard label="Realm Tax" value={`${data.tax_percent}%`} />
      </div>
      <div style={{ marginTop: '12px', color: INK_SOFT, fontStyle: 'italic' }}>
        {data.worthy
          ? 'You hold authority over this court. Don the crown to issue commands.'
          : 'Only the rightful Ruler or appointed Regent may command from this throne.'}
        {!data.cooldown_ok && (
          <span style={{ color: RED }}> The throne must gather its strength before speaking again.</span>
        )}
      </div>
    </Section>
  );
};

const CommandsTab = (props: { data: ThroneData; act: ActFn }) => {
  const { data, act } = props;
  const [announce, setAnnounce] = useState('');
  const [decree, setDecree] = useState('');
  const [outlaw, setOutlaw] = useState('');
  const [pardon, setPardon] = useState('');
  const canAnnounce = !!data.can_announce;
  const canCommand = !!data.can_command;

  return (
    <>
      <Section title="Public Writs">
        <div style={{ color: INK_SOFT, marginBottom: '6px' }}>Broadcast a realm-wide message. (Requires the crown.)</div>
        <textarea
          style={{ ...inputStyle, height: '54px', resize: 'none' }}
          value={announce}
          placeholder="Speak your announcement to the realm..."
          onChange={(e) => setAnnounce(e.target.value)}
        />
        <div style={{ marginTop: '6px', textAlign: 'right' }}>
          <button
            type="button"
            style={btn({ disabled: !canAnnounce || !announce.trim() })}
            disabled={!canAnnounce || !announce.trim()}
            onClick={() => {
              act('make_announcement', { text: announce });
              setAnnounce('');
            }}
          >
            Make Announcement
          </button>
        </div>
      </Section>

      <Section title="Governance">
        <div style={{ color: INK_SOFT, marginBottom: '6px' }}>Issue a royal decree. (Ruler or Regent, crown required.)</div>
        <textarea
          style={{ ...inputStyle, height: '48px', resize: 'none' }}
          value={decree}
          placeholder="Decree the will of the crown..."
          onChange={(e) => setDecree(e.target.value)}
        />
        <div style={{ marginTop: '6px', textAlign: 'right' }}>
          <button
            type="button"
            style={btn({ disabled: !canCommand || !decree.trim() })}
            disabled={!canCommand || !decree.trim()}
            onClick={() => {
              act('make_decree', { text: decree });
              setDecree('');
            }}
          >
            Issue Decree
          </button>
        </div>

        <div style={{ display: 'flex', gap: '8px', marginTop: '12px', flexWrap: 'wrap' }}>
          <button type="button" style={btn({ disabled: !canCommand })} disabled={!canCommand} onClick={() => act('set_taxes')}>
            Set Taxes
          </button>
          <button type="button" style={btn({ disabled: !canCommand })} disabled={!canCommand} onClick={() => act('appoint_regent')}>
            Appoint Regent
          </button>
          <button type="button" style={btn({ disabled: !canCommand })} disabled={!canCommand} onClick={() => act('change_position')}>
            Change Position
          </button>
          <button type="button" style={btn({ disabled: !canCommand, tone: 'red' })} disabled={!canCommand} onClick={() => act('silence')}>
            SILENCE!!
          </button>
        </div>
      </Section>

      <Section title="Justice">
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center', marginBottom: '8px' }}>
          <input
            style={{ ...inputStyle, flex: 1 }}
            value={outlaw}
            placeholder="Name to outlaw..."
            onChange={(e) => setOutlaw(e.target.value)}
          />
          <button
            type="button"
            style={btn({ disabled: !canCommand || !outlaw.trim(), tone: 'red' })}
            disabled={!canCommand || !outlaw.trim()}
            onClick={() => {
              act('declare_outlaw', { name: outlaw });
              setOutlaw('');
            }}
          >
            Declare Outlaw
          </button>
        </div>
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
          <input
            style={{ ...inputStyle, flex: 1 }}
            value={pardon}
            placeholder="Name to pardon..."
            onChange={(e) => setPardon(e.target.value)}
          />
          <button
            type="button"
            style={btn({ disabled: !canCommand || !pardon.trim(), tone: 'green' })}
            disabled={!canCommand || !pardon.trim()}
            onClick={() => {
              act('pardon_outlaw', { name: pardon });
              setPardon('');
            }}
          >
            Pardon
          </button>
        </div>
      </Section>

      <Section title="Regalia">
        <div style={{ display: 'flex', gap: '8px', flexWrap: 'wrap' }}>
          <button type="button" style={btn()} onClick={() => act('summon_crown')}>
            Summon Crown
          </button>
          <button type="button" style={btn({ disabled: !canAnnounce })} disabled={!canAnnounce} onClick={() => act('summon_key')}>
            Summon Key
          </button>
          <button type="button" style={btn({ tone: 'gold' })} onClick={() => act('help')}>
            Help
          </button>
        </div>
      </Section>

      <Section title="Heraldry">
        <div style={{ display: 'flex', alignItems: 'center', gap: '14px' }}>
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              width: '56px',
              height: '56px',
              background: '#100c08',
              border: `1px solid ${BORDER}`,
              borderRadius: '3px',
              flexShrink: 0,
            }}
          >
            <DmIcon icon={data.flag_icon} icon_state={data.flag_state} width="48px" height="48px" />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ display: 'flex', gap: '14px', marginBottom: '8px' }}>
              <Swatch label="Primary" color={data.lord_primary} />
              <Swatch label="Secondary" color={data.lord_secondary} />
            </div>
            <button
              type="button"
              style={btn({ disabled: !canCommand })}
              disabled={!canCommand}
              onClick={() => act('change_colors')}
            >
              Change Heraldry Colour
            </button>
          </div>
        </div>
      </Section>
    </>
  );
};

const ListTab = (props: { data: ThroneData; act: ActFn }) => {
  const { data, act } = props;
  const [law, setLaw] = useState('');
  const canCommand = !!data.can_command;

  return (
    <>
      <Section title="Laws of the Land">
        <div style={{ display: 'flex', gap: '8px', alignItems: 'center', marginBottom: '10px' }}>
          <input
            style={{ ...inputStyle, flex: 1 }}
            value={law}
            placeholder="Proclaim a new law..."
            onChange={(e) => setLaw(e.target.value)}
          />
          <button
            type="button"
            style={btn({ disabled: !canCommand || !law.trim() })}
            disabled={!canCommand || !law.trim()}
            onClick={() => {
              act('make_law', { text: law });
              setLaw('');
            }}
          >
            Make Law
          </button>
          <button
            type="button"
            style={btn({ disabled: !canCommand || data.laws.length === 0, tone: 'red' })}
            disabled={!canCommand || data.laws.length === 0}
            onClick={() => act('purge_laws')}
          >
            Purge All
          </button>
        </div>
        {data.laws.length === 0 ? (
          <div style={{ color: INK_SOFT, fontStyle: 'italic' }}>No laws have been declared.</div>
        ) : (
          data.laws.map((text, i) => (
            <div
              key={i}
              style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '4px 0', borderBottom: `1px solid ${BORDER}` }}
            >
              <span style={{ color: GOLD_SOFT, flexShrink: 0, width: '22px' }}>{i + 1}.</span>
              <span style={{ flex: 1 }}>{text}</span>
              <button
                type="button"
                style={btn({ disabled: !canCommand, tone: 'red' })}
                disabled={!canCommand}
                onClick={() => act('remove_law', { index: i + 1 })}
              >
                Remove
              </button>
            </div>
          ))
        )}
      </Section>

      <Section title="Royal Decrees">
        {data.decrees.length === 0 ? (
          <div style={{ color: INK_SOFT, fontStyle: 'italic' }}>No decrees stand. Issue one from the Commands tab.</div>
        ) : (
          data.decrees.map((text, i) => (
            <div
              key={i}
              style={{ display: 'flex', alignItems: 'center', gap: '8px', padding: '4px 0', borderBottom: `1px solid ${BORDER}` }}
            >
              <span style={{ color: GOLD_SOFT, flexShrink: 0, width: '22px' }}>{i + 1}.</span>
              <span style={{ flex: 1 }}>{text}</span>
              <button
                type="button"
                style={btn({ disabled: !canCommand, tone: 'red' })}
                disabled={!canCommand}
                onClick={() => act('remove_decree', { index: i + 1 })}
              >
                Remove
              </button>
            </div>
          ))
        )}
      </Section>

      <Section title="Outlaws">
        {data.outlaws.length === 0 ? (
          <div style={{ color: INK_SOFT, fontStyle: 'italic' }}>No outlaws are named.</div>
        ) : (
          data.outlaws.map((name, i) => (
            <div key={i} style={{ padding: '3px 0', borderBottom: `1px solid ${BORDER}`, color: RED }}>
              {name}
            </div>
          ))
        )}
      </Section>
    </>
  );
};

// --- Root ------------------------------------------------------------------
export const Throne = () => {
  const { act, data } = useBackend<ThroneData>();
  const [tab, setTab] = useState('overview');

  return (
    <Window width={880} height={720}>
      <Window.Content scrollable>
        <div style={pageStyle}>
          <div style={headerStyle}>
            <div>
              <div style={titleStyle}>Ducal Court</div>
              <div style={{ color: INK_SOFT, fontStyle: 'italic' }}>Hold court from the throne of Rivermist Hollow</div>
            </div>
            <div style={{ textAlign: 'right', fontSize: '12px' }}>
              <div>
                <span style={{ color: INK_SOFT }}>Ruler: </span>
                <span style={{ color: GOLD, fontWeight: 'bold' }}>{data.ruler_name}</span>
              </div>
              <div>
                <span style={{ color: INK_SOFT }}>Regent: </span>
                <span style={{ color: GOLD, fontWeight: 'bold' }}>{data.regent_name}</span>
              </div>
              <div>
                <span style={{ color: INK_SOFT }}>Your Standing: </span>
                <span style={{ color: data.worthy ? GREEN : INK_SOFT, fontWeight: 'bold' }}>
                  {data.is_ruler ? 'Ruler' : data.is_regent ? 'Regent' : 'Subject'}
                </span>
              </div>
            </div>
          </div>

          <div style={tabBarStyle}>
            <button type="button" style={tabStyle(tab === 'overview')} onClick={() => setTab('overview')}>
              Overview
            </button>
            <button type="button" style={tabStyle(tab === 'commands')} onClick={() => setTab('commands')}>
              Ducal Commands
            </button>
            <button type="button" style={tabStyle(tab === 'laws')} onClick={() => setTab('laws')}>
              Laws &amp; Decrees
            </button>
          </div>

          {tab === 'overview' && <Overview data={data} />}
          {tab === 'commands' && <CommandsTab data={data} act={act} />}
          {tab === 'laws' && <ListTab data={data} act={act} />}
        </div>
      </Window.Content>
    </Window>
  );
};
