import React from 'react';
import {
  AbsoluteFill,
  Audio,
  Composition,
  Img,
  Sequence,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
  interpolate,
  registerRoot,
} from 'remotion';

const scenes = [
  {
    duration: 120,
    eyebrow: 'WELCOME TO THE ADVENTURE',
    title: 'English Fun',
    body: 'A joyful English playground for curious kids.',
    chips: ['Play', 'Speak', 'Learn'],
    shots: ['01-home.png'],
  },
  {
    duration: 150,
    eyebrow: 'A CLEAR PATH TO PROGRESS',
    title: 'Grow one word at a time',
    body: 'Follow colorful lessons from Alphabet Fun to new worlds of vocabulary.',
    chips: ['Grades 1–6', '56 units'],
    shots: ['02-grade-map.png', '03-unit-detail.png'],
  },
  {
    duration: 150,
    eyebrow: 'PRACTICE THAT FEELS LIKE PLAY',
    title: 'Learn it. Say it. Own it.',
    body: 'Flashcards, quizzes, pronunciation, memory and spelling keep every session fresh.',
    chips: ['Vocabulary', 'Speaking', 'Spelling'],
    shots: ['04-learn-card.png', '05-quiz.png'],
  },
  {
    duration: 150,
    eyebrow: 'THE ARCADE IS OPEN',
    title: 'Turn practice into play',
    body: 'Jump into quick games that make English words stick.',
    chips: ['Balloon Pop', 'Simon Says', 'Stories'],
    shots: ['06-arcade.png'],
  },
  {
    duration: 150,
    eyebrow: 'MADE FOR FAMILIES',
    title: 'A calm view for parents',
    body: 'See streaks, stars, daily goals and learning progress in one friendly dashboard.',
    chips: ['Progress', 'Daily goals', 'Parent controls'],
    shots: ['07-parents.png'],
  },
  {
    duration: 120,
    eyebrow: 'MORE TO DISCOVER',
    title: 'Collect. Explore. Keep going.',
    body: 'Build confidence through playful repetition and small wins every day.',
    chips: ['440+ words', 'Offline-first', 'Ad-free option'],
    shots: ['08-pets.png', '01-home.png'],
  },
  {
    duration: 60,
    eyebrow: 'YOUR NEXT ADVENTURE STARTS HERE',
    title: 'English Fun',
    body: 'Learn one joyful word at a time.',
    chips: ['For curious learners', 'For cheering grown-ups'],
    shots: ['01-home.png'],
  },
];

const totalDuration = scenes.reduce((sum, scene) => sum + scene.duration, 0);

function getScene(frame) {
  let start = 0;
  for (let index = 0; index < scenes.length; index += 1) {
    const scene = scenes[index];
    if (frame < start + scene.duration) return {scene, index, start};
    start += scene.duration;
  }
  return {scene: scenes[scenes.length - 1], index: scenes.length - 1, start: totalDuration - scenes[scenes.length - 1].duration};
}

function FloatingShapes() {
  return (
    <>
      <div style={{position: 'absolute', width: 520, height: 520, borderRadius: 999, background: 'rgba(109,96,255,.32)', top: -240, right: -170}} />
      <div style={{position: 'absolute', width: 320, height: 320, borderRadius: 999, background: 'rgba(255,139,87,.28)', bottom: -170, left: -110}} />
      <div style={{position: 'absolute', width: 14, height: 14, borderRadius: 99, background: '#ffe36e', top: 116, left: 920}} />
      <div style={{position: 'absolute', width: 9, height: 9, borderRadius: 99, background: '#fff', top: 260, left: 820, opacity: .7}} />
      <div style={{position: 'absolute', width: 12, height: 12, borderRadius: 99, background: '#fff', bottom: 118, right: 190, opacity: .6}} />
    </>
  );
}

function BrandMark({small = false}) {
  return (
    <div style={{display: 'flex', alignItems: 'center', gap: small ? 10 : 14}}>
      <Img src={staticFile('icon.png')} style={{width: small ? 48 : 68, height: small ? 48 : 68, borderRadius: small ? 14 : 19}} />
      <div style={{fontSize: small ? 23 : 28, fontWeight: 900, letterSpacing: 1.5, color: '#fff'}}>ENGLISH FUN</div>
    </div>
  );
}

function Chip({children, index}) {
  const colors = ['#ffb55f', '#76dbbb', '#8ca6ff', '#f193c2'];
  return (
    <div style={{padding: '10px 18px', borderRadius: 999, background: colors[index % colors.length], color: '#18204d', fontWeight: 800, fontSize: 20, boxShadow: '0 7px 0 rgba(0,0,0,.12)'}}>
      {children}
    </div>
  );
}

function PhoneShot({file, index, total}) {
  const frame = useCurrentFrame();
  const entry = interpolate(frame, [0, 26], [60, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const scale = interpolate(frame, [0, 50, 150], [0.92, 1, 1.02], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const width = total === 1 ? 360 : 280;
  const height = total === 1 ? 780 : 606;
  const tilt = total === 1 ? 0 : (index === 0 ? -5 : 5);
  return (
    <div style={{width, height, padding: 10, borderRadius: 32, background: '#fdfaff', boxShadow: '0 25px 45px rgba(0,0,0,.34)', transform: `translateY(${entry}px) rotate(${tilt}deg) scale(${scale})`, overflow: 'hidden'}}>
      <Img src={staticFile(`screens/${file}`)} style={{width: '100%', height: '100%', objectFit: 'cover', objectPosition: 'top', borderRadius: 24}} />
    </div>
  );
}

function PromoScene({scene}) {
  const frame = useCurrentFrame();
  const {width} = useVideoConfig();
  const fade = interpolate(frame, [0, 10], [0.82, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const titleY = interpolate(frame, [0, 25], [40, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  return (
    <AbsoluteFill style={{opacity: fade, padding: '72px 86px', color: '#fff'}}>
      <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
        <BrandMark />
        <div style={{fontSize: 18, fontWeight: 800, letterSpacing: 1.4, opacity: .74}}>FLUXLAB ORIGINAL</div>
      </div>
      <div style={{display: 'flex', flex: 1, alignItems: 'center', gap: 54}}>
        <div style={{width: width * .48, transform: `translateY(${titleY}px)`}}>
          <div style={{fontSize: 18, fontWeight: 900, letterSpacing: 2.4, color: '#ffe36e'}}>{scene.eyebrow}</div>
          <div style={{marginTop: 18, fontSize: 67, lineHeight: 1.02, fontWeight: 900, letterSpacing: -.8}}>{scene.title}</div>
          <div style={{marginTop: 22, fontSize: 28, lineHeight: 1.28, color: 'rgba(255,255,255,.82)', maxWidth: 690}}>{scene.body}</div>
          <div style={{display: 'flex', flexWrap: 'wrap', gap: 12, marginTop: 34}}>
            {scene.chips.map((chip, index) => <Chip key={chip} index={index}>{chip}</Chip>)}
          </div>
        </div>
        <div style={{display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 26, flex: 1, minHeight: 760}}>
          {scene.shots.map((file, index) => <PhoneShot key={file} file={file} index={index} total={scene.shots.length} />)}
        </div>
      </div>
      <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center', color: 'rgba(255,255,255,.56)', fontSize: 17, fontWeight: 700}}>
        <div>English Fun · Learn through play</div>
        <div>{String(scene.shots.length).padStart(2, '0')} / 08</div>
      </div>
    </AbsoluteFill>
  );
}

function Promo() {
  const frame = useCurrentFrame();
  const {scene, index, start} = getScene(frame);
  return (
    <AbsoluteFill style={{background: 'linear-gradient(135deg, #18204d 0%, #3f3278 62%, #b56a91 100%)', fontFamily: 'Arial Rounded MT Bold, Trebuchet MS, sans-serif', overflow: 'hidden'}}>
      <FloatingShapes />
      <Sequence from={0} durationInFrames={totalDuration}><Audio src={staticFile('fanfare.wav')} volume={0.22} /></Sequence>
      <Sequence from={240} durationInFrames={1}><Audio src={staticFile('win.wav')} volume={0.14} /></Sequence>
      <Sequence from={450} durationInFrames={1}><Audio src={staticFile('star.wav')} volume={0.12} /></Sequence>
      <Sequence from={660} durationInFrames={1}><Audio src={staticFile('ding.wav')} volume={0.12} /></Sequence>
      <Sequence from={start} durationInFrames={scene.duration} key={index}>
        <PromoScene scene={scene} />
      </Sequence>
    </AbsoluteFill>
  );
}

function FeatureGraphic() {
  return (
    <AbsoluteFill style={{background: 'linear-gradient(125deg,#5d52e7 0%,#a16cf0 53%,#ff9a66 100%)', fontFamily: 'Arial Rounded MT Bold, Trebuchet MS, sans-serif', color: '#fff', overflow: 'hidden', padding: 42}}>
      <div style={{position: 'absolute', width: 420, height: 420, borderRadius: 999, background: 'rgba(255,255,255,.11)', right: -110, top: -170}} />
      <div style={{position: 'absolute', width: 240, height: 240, borderRadius: 999, background: 'rgba(29,31,92,.12)', left: -90, bottom: -100}} />
      <div style={{display: 'flex', height: '100%', alignItems: 'center', gap: 46}}>
        <div style={{width: 570, paddingLeft: 20}}>
          <div style={{display: 'flex', alignItems: 'center', gap: 16}}>
            <Img src={staticFile('icon.png')} style={{width: 78, height: 78, borderRadius: 22}} />
            <div style={{fontSize: 24, fontWeight: 900, letterSpacing: 2}}>ENGLISH FUN</div>
          </div>
          <div style={{marginTop: 25, fontSize: 62, fontWeight: 900, lineHeight: 1.02}}>Play. Speak.<br />Learn.</div>
          <div style={{marginTop: 16, fontSize: 25, lineHeight: 1.25, color: 'rgba(255,255,255,.9)'}}>A colorful English adventure for curious kids.</div>
          <div style={{marginTop: 22, fontSize: 19, fontWeight: 800, color: '#fff2a1'}}>Grades 1–6  ·  Games  ·  Stories  ·  Progress</div>
        </div>
        <div style={{height: 450, width: 215, padding: 7, background: '#fff', borderRadius: 24, transform: 'rotate(7deg)', boxShadow: '0 22px 38px rgba(34,26,93,.32)'}}>
          <Img src={staticFile('screens/01-home.png')} style={{width: '100%', height: '100%', objectFit: 'cover', objectPosition: 'top', borderRadius: 18}} />
        </div>
        <div style={{height: 320, width: 154, padding: 6, background: '#fff', borderRadius: 20, transform: 'rotate(-7deg) translateY(34px)', boxShadow: '0 18px 32px rgba(34,26,93,.25)'}}>
          <Img src={staticFile('screens/06-arcade.png')} style={{width: '100%', height: '100%', objectFit: 'cover', objectPosition: 'top', borderRadius: 15}} />
        </div>
      </div>
    </AbsoluteFill>
  );
}

export const RemotionRoot = () => (
  <>
    <Composition id="Promo" component={Promo} durationInFrames={totalDuration} fps={30} width={1920} height={1080} />
    <Composition id="FeatureGraphic" component={FeatureGraphic} durationInFrames={1} fps={30} width={1024} height={500} />
  </>
);

registerRoot(RemotionRoot);
