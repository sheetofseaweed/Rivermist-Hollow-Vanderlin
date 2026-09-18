const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const source = fs.readFileSync(path.join(__dirname, '../code/native_say/_base.dm'), 'utf8');
const script = source.split('<script>')[1].split('</script>')[0]
	.replace(/\[default_channel\]/g, 'Say')
	.replace(/\[channels_json\]/g, '["Say","Me"]')
	.replace(/\[quiet_json\]/g, '[]')
	.replace(/\[max_length - 1\]/g, '2047')
	.replace(/\[ref\(src\)\]/g, '[0x12345678]')
	.replace(/\[(\d+) \* scale\]/g, '$1')
	.replace(/\\([\\\[\]])/g, '$1');

function fixture(chromium = true) {
	const elements = {};
	const requests = [];
	const timers = new Map();
	let timerId = 0;
	const context = {
		console,
		setTimeout(fn, delay) { timers.set(++timerId, { fn, delay }); return timerId; },
		clearTimeout(id) { timers.delete(id); },
		document: {
			getElementById(id) {
				return elements[id] ||= {
					style: {}, textContent: '', innerHTML: '',
					addEventListener() {}, focus() {}, blur() {},
				};
			},
			addEventListener() {},
		},
		XMLHttpRequest: class {
			open(method, url) { this.url = url; }
			send() { requests.push(this.url); }
		},
	};
	context.window = context;
	if (chromium) context.cef_to_byond = url => requests.push(url);
	vm.createContext(context);
	vm.runInContext(script, context);
	return { context, requests, timers, elements };
}

for (const chromium of [true, false]) {
	const { context: c, requests, timers, elements } = fixture(chromium);
	c.openSayWindow('Me');
	c.realText = 'a'.repeat(1500);
	c.submitEntry();
	assert.equal(c.windowOpen, false, 'submission closes immediately');
	assert.equal(c.chatHistory[0].text.length, 1500);
	assert.equal(c.chatHistory[0].status, 'pending');
	assert.equal(requests.filter(url => url.includes('action=entry')).length, 1);
	const first = c.chatHistory[0];
	c.openSayWindow('Say');
	c.realText = 'new draft';
	c.receiveEntryReceipt(first.id, 'received');
	assert.equal(c.realText, 'new draft', 'old receipt preserves current draft');
	assert.equal(c.windowOpen, true);
	assert.equal(first.status, 'received');
	assert.equal(timers.has(first.timer), false);

	c.realText = 'é'.repeat(900);
	c.submitEntry();
	const unicodeRequest = requests.find(url => url.includes('%C3%A9'));
	assert.ok(unicodeRequest.length > 2048, 'encoded request exceeds navigation limit');
	assert.equal(new URLSearchParams(unicodeRequest.split('?')[1]).get('entry'), 'é'.repeat(900));
	const pending = c.chatHistory[0];
	timers.get(pending.timer).fn();
	assert.equal(pending.status, 'unconfirmed');
	assert.match(elements.deliveryStatus.textContent, /unconfirmed/);
	assert.equal(requests.filter(url => url.includes('action=entry')).length, 2, 'timeout never resends');
	c.receiveEntryReceipt(pending.id, 'received');
	assert.equal(pending.status, 'received', 'late receipt resolves uncertainty');

	c.openSayWindow('Say');
	for (const text of ['a'.repeat(2048), 'é'.repeat(1024), '\ud800']) {
		c.realText = text;
		c.submitEntry();
		assert.equal(c.windowOpen, true);
		assert.equal(c.realText, text, 'invalid draft remains editable');
	}
	c.realText = 'a'.repeat(2047);
	c.submitEntry();
	assert.equal(c.windowOpen, false, 'maximum valid byte length is accepted');
	c.receiveEntryReceipt(c.chatHistory[0].id, 'rejected');
	assert.equal(c.chatHistory[0].status, 'rejected');
	assert.match(elements.deliveryStatus.textContent, /rejected/);
}

{
	const { context: c, requests } = fixture();
	c.cef_to_byond = url => {
		if (url.includes('action=close')) throw new Error('close failed');
		requests.push(url);
	};
	c.openSayWindow('Say');
	c.realText = 'send despite close failure';
	c.submitEntry();
	assert.ok(requests.some(url => url.includes('action=entry')));
}

{
	const { context: c } = fixture();
	for (let i = 0; i < 20; i++) {
		c.openSayWindow('Say');
		c.realText = `pending ${i}`;
		c.submitEntry();
	}
	c.openSayWindow('Say');
	c.realText = 'retain this draft';
	c.submitEntry();
	assert.equal(c.chatHistory.length, 20);
	assert.equal(c.realText, 'retain this draft');
	assert.equal(c.windowOpen, true, 'history pressure does not discard unconfirmed messages');
}

console.log('Native say tests passed: transport branches, byte limits, receipts, draft retention, timeout, and history bounds.');
