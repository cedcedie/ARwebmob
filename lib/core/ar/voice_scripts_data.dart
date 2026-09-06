// Voice-over narration for the AR lessons.
//
// Provenance differs by entry:
//   * 'onboarding' and q1w1-q1w5 are ported verbatim from the retired
//     ar-science-explorer web app's src/data/voiceScripts.ts. Leave them as-is.
//   * q1w6 through q3w8 were drafted in-repo from the school's own lesson
//     modules — the MATATAG Grade 7 lesson exemplars for each week — using each
//     module's learning objectives, content outline, explicitation text, worked
//     examples, and formative-assessment answer keys. Every spoken statement is
//     traceable to that week's module, NOT to the short summary blurbs in
//     lib/core/data/curriculum_data.dart, which in several weeks (notably q3w1)
//     describe different content than the module actually teaches.
//
// PENDING CLIENT REVIEW: the q1w6-q3w8 scripts have not yet been signed off by
// the client. The Filipino lines in particular need a native-speaker pass
// before students hear them; they were drafted to match the Taglish register of
// the ported q1w1-q1w5 entries (English technical terms kept inside Filipino
// sentences) but have not been reviewed by a Filipino science teacher.
//
// Format rules if you add or edit entries: the key is the lesson id, each
// lesson holds 'en' and 'Filipino' lists, and each list is spoken aloud by
// text-to-speech — so write for the ear. No bullets, symbols, abbreviations,
// digits, or parentheses.

const Map<String, Map<String, List<String>>> kVoiceScripts = {
  'onboarding': {
    'en': [
      'Welcome to AR Science Explorer. This app will help you learn science through augmented reality.',
      'Use the AR camera to scan colored objects and see 3D models of scientific concepts.',
      'You can rotate, zoom, and interact with the models to understand better.',
      'Complete tests to unlock new subjects and check your knowledge.',
      'Conduct virtual experiments in the lab section.',
      'Try out the AR camera now by pointing it at any colored surface.',
    ],
    'Filipino': [
      'Maligayang pagdating sa AR Science Explorer. Ang app na ito ay tutulong sa iyo na matuto ng agham sa pamamagitan ng augmented reality.',
      'Gamitin ang AR camera upang i-scan ang mga kulay na bagay at makita ang 3D na mga modelo ng mga konsepto sa agham.',
      'Maaari mong i-rotate, i-zoom, at makipag-ugnayan sa mga modelo upang mas maunawaan nang mabuti.',
      'Kumpletuhin ang mga pagsusulit upang i-unlock ang mga bagong paksa at subukan ang iyong kaalaman.',
      'Magsagawa ng mga virtual na eksperimento sa lab section.',
      'Subukan ang AR camera ngayon sa pamamagitan ng pagtutok nito sa anumang makulay na ibabaw.',
    ],
  },
  'q1w1': {
    'en': [
      'Scientists use models to explain things too small to see directly. Let\'s explore how the particle model helps us understand matter.',
      'The Particle Model of Matter states that all matter is made up of tiny particles. Each pure substance has its own unique particles.',
      'In solids, particles are tightly packed and vibrate in place. In liquids, they move freely but stay close. In gases, they spread far apart.',
    ],
    'Filipino': [
      'Gumagamit ang mga siyentipiko ng mga modelo upang ipaliwanag ang mga bagay na masyadong maliit upang makita nang direkta. Tuklasin natin kung paano nakakatulong ang particle model sa atin na maunawaan ang materia.',
      'Ang Particle Model of Matter ay nagsasaad na ang lahat ng materia ay binubuo ng mga miligang maliliit na partikula. Bawat purong sangkap ay may sariling natatanging mga partikula.',
      'Sa mga solido, ang mga partikula ay mahigpit na nakabalot at gumagalaw sa lugar. Sa mga likido, sila ay kumakalat nang malaya ngunit manatiling malapit. Sa mga gas, sila ay kumalat nang malayo.',
    ],
  },
  'q1w2': {
    'en': [
      'A pure substance contains only one type of particle. Elements are pure substances made of one type of atom, while compounds have two or more.',
      'The Kinetic Molecular Theory explains that particles are always in constant, random motion. The warmer the substance, the faster the particles move.',
      'Temperature directly affects particle motion. When you heat a substance, the particles move faster and take up more space, causing expansion.',
    ],
    'Filipino': [
      'Ang isang purong sangkap ay naglalaman lamang ng isang uri ng partikula. Ang mga elemento ay mga purong sangkap na gawa sa isang uri ng atomo, habang ang mga compound ay may dalawa o higit pa.',
      'Ang Kinetic Molecular Theory ay nagpapaliwanag na ang mga partikula ay palaging nasa patuloy na, random na paggalaw. Mas mainit ang sangkap, mas mabilis na gumagalaw ang mga partikula.',
      'Ang temperatura ay direktang nakakaapekto sa paggalaw ng partikula. Kapag pinainit mo ang isang sangkap, ang mga partikula ay gumagalaw nang mas mabilis at sumasaklaw ng mas maraming espasyo.',
    ],
  },
  'q1w3': {
    'en': [
      'Let\'s examine how particles are arranged differently in solids, liquids, and gases. Understanding particle arrangement helps explain the properties of each state.',
      'In the solid state, particles vibrate but stay in fixed positions creating a rigid structure. Liquids have particles that can flow freely while maintaining close contact.',
      'Gas particles have the most freedom. They move rapidly in all directions, spreading far apart to fill any container. Changes of state involve rearranging these particles.',
    ],
    'Filipino': [
      'Tingnan natin kung paano ang mga partikula ay inayos nang iba sa mga solido, likido, at gas. Ang pag-unawa sa arrangement ng partikula ay tumutulong na ipaliwanag ang mga katangian ng bawat estado.',
      'Sa solid state, ang mga partikula ay gumagalaw ngunit manatiling nasa nakatatag na mga posisyon na lumilikha ng matatag na istraktura. Ang mga likido ay may mga partikula na maaaring lumabas nang malaya habang pinapanatili ang malapit na kontak.',
      'Ang gas particles ay may pinakamaraming kalayaan. Sila ay mabilis na gumagalaw sa lahat ng direksyon, kumalat nang malayo upang mapuno ang anumang lalagyan. Ang mga pagbabago ng estado ay nagsasangkot ng pag-aayos ng mga partikula na ito.',
    ],
  },
  'q1w4': {
    'en': [
      'A scientific investigation starts with identifying the aim or problem you want to solve. This guides the entire experiment and helps you stay focused.',
      'Next, list all the materials and equipment you\'ll need. Being thorough ensures you have everything required before beginning the experiment.',
      'Finally, outline your procedures step by step. Clear instructions allow others to replicate your experiment and verify your results independently.',
    ],
    'Filipino': [
      'Ang isang scientific investigation ay nagsisimula sa pagkilala sa layunin o problema na nais mong malutas. Ito ay gumagabay sa buong eksperimento at tumutulong sa iyo na manatiling nakatuon.',
      'Susunod, listahan ang lahat ng mga materyales at kagamitan na kailangan mo. Ang pagiging komprehensibo ay nagsisiguro na mayroon kang lahat ng kinakailangan bago magsimula ng eksperimento.',
      'Sa wakas, balangkasin ang iyong mga pamamaraan nang hakbang-hakbang. Ang mga malinaw na tagubilin ay nagpapahintulot sa iba na ulitin ang iyong eksperimento at i-verify ang iyong mga resulta nang independyente.',
    ],
  },
  'q1w5': {
    'en': [
      'In any experiment, the independent variable is what you deliberately change or manipulate. This is the factor you\'re testing to see its effect.',
      'The dependent variable is what you measure or observe. It "depends" on the independent variable. This is where you collect your data.',
      'Controlled variables are factors you keep constant. By controlling these, you ensure that any changes in the dependent variable are due solely to your independent variable.',
    ],
    'Filipino': [
      'Sa anumang eksperimento, ang independent variable ay kung ano ang layunin mong baguhin o i-manipulate. Ito ang salik na sinusubukan mo upang makita ang epekto nito.',
      'Ang dependent variable ay kung ano ang sinusukat o sinusundan mo. Ito ay "nakadepende" sa independent variable. Dito mo kinokolekta ang iyong datos.',
      'Ang mga controlled variables ay mga salik na pinapanatili mong pare-pareho. Sa pamamagitan ng pagkontrol sa mga ito, tinitiyak mo na ang anumang pagbabago sa dependent variable ay dahil lamang sa iyong independent variable.',
    ],
  },
  'q1w6': {
    'en': [
      'This lesson is about making accurate measurements using standard units. Our country uses the International System of Units, so length is measured in meters, mass in kilograms, time in seconds, the volume of a liquid in liters, and temperature is commonly read in degrees Celsius.',
      'Before you use any measuring instrument, find its least count, which is the smallest value that its scale can read. Knowing the least count and reading the scale carefully is what makes a measurement accurate.',
      'Measuring produces raw data that piles up quickly, so organize it in a table with a clear title and one measured quantity in each column. This week you also meet the parts of a solution. The solute is the substance that dissolves, the solvent is the liquid it dissolves into, and sugar is soluble in water while sand is insoluble.',
    ],
    'Filipino': [
      'Ang aralin na ito ay tungkol sa paggawa ng tumpak na sukat gamit ang standard units. Ginagamit sa ating bansa ang International System of Units, kaya ang haba ay sinusukat sa meter, ang mass sa kilogram, ang oras sa segundo, ang volume ng likido sa liter, at ang temperatura ay karaniwang binabasa sa degrees Celsius.',
      'Bago gumamit ng anumang panukat, alamin muna ang least count nito, ang pinakamaliit na halagang kayang basahin ng iskala nito. Ang pag-alam sa least count at ang maingat na pagbasa ng iskala ang nagpapatumpak sa iyong sukat.',
      'Ang pagsukat ay nagbubunga ng maraming raw data, kaya ayusin ito sa isang talahanayan na may malinaw na pamagat at isang sinukat na dami sa bawat kolum. Makikilala mo rin ngayong linggo ang mga bahagi ng solution. Ang solute ang sangkap na natutunaw, ang solvent ang likidong pinagtutunawan nito, at ang asukal ay soluble sa tubig samantalang ang buhangin ay insoluble.',
    ],
  },
  'q1w7': {
    'en': [
      'A solution is a homogeneous mixture. It looks the same throughout, only one phase can be seen, and its solute and solvent cannot be separated by filtering.',
      'An unsaturated solution can still dissolve more solute. A saturated solution is already at its maximum, so any extra solute you add will no longer dissolve, and a supersaturated solution holds even more solute than that and crystallizes rapidly.',
      'Concentration tells us how much solute a solution contains. Percent by mass is the number of grams of solute in every one hundred grams of solution, and percent by volume works the same way for liquids, the way seventy percent rubbing alcohol means seventy milliliters of alcohol in every one hundred milliliters.',
    ],
    'Filipino': [
      'Ang solution ay isang homogeneous mixture. Pare-pareho ang anyo nito sa lahat ng bahagi, isang phase lamang ang nakikita, at hindi mapaghihiwalay ang solute at solvent nito sa pamamagitan ng filtration.',
      'Ang unsaturated solution ay kaya pang tunawin ang dagdag na solute. Ang saturated solution ay nasa hangganan na nito, kaya hindi na matutunaw ang sobrang solute na idadagdag mo, at ang supersaturated solution ay may sobra pang solute at mabilis mag-crystallize.',
      'Ipinapakita ng concentration kung gaano karaming solute ang nasa isang solution. Ang percent by mass ay ang bilang ng gramo ng solute sa bawat isang daang gramo ng solution, at ganoon din ang percent by volume para sa likido, tulad ng pitumpung porsyentong rubbing alcohol na may pitumpung milliliter ng alcohol sa bawat isang daang milliliter.',
    ],
  },
  'q1w8': {
    'en': [
      'Solubility is the degree to which a substance dissolves in a solvent to make a solution. The rate of dissolving depends on three factors. These are the temperature, the agitation or stirring, and the size of the particles.',
      'For most solids, dissolving is faster in hot water, because the solvent molecules have greater kinetic energy and collide with the undissolved solute more often. Stirring brings fresh solvent into contact with the solute, and breaking the solute into smaller pieces increases the surface area touching the solvent.',
      'Solutions can also be tested with litmus paper. An acid such as vinegar turns blue litmus paper red, a base such as soap or dishwashing liquid turns red litmus paper blue, and a salt solution produces no color change. Always handle science equipment properly while you carry out these tests.',
    ],
    'Filipino': [
      'Ang solubility ay ang antas kung gaano natutunaw ang isang sangkap sa solvent upang makabuo ng solution. Ang bilis ng pagkatunaw ay nakadepende sa tatlong salik. Ito ay ang temperatura, ang paghahalo o agitation, at ang laki ng mga partikula.',
      'Para sa karamihan ng solid, mas mabilis ang pagkatunaw sa mainit na tubig, dahil mas malaki ang kinetic energy ng mga molecule ng solvent at mas madalas nilang nababangga ang hindi pa natutunaw na solute. Ang paghahalo ay nagdadala ng sariwang solvent sa solute, at ang paggawang mas maliliit na piraso ng solute ay nagpapalaki sa surface area na dumidikit sa solvent.',
      'Maaari ring subukin ang mga solution gamit ang litmus paper. Ang acid tulad ng suka ay nagpapapula sa asul na litmus paper, ang base tulad ng sabon o dishwashing liquid ay nagpapaasul sa pulang litmus paper, at ang salt solution ay walang naidudulot na pagbabago sa kulay. Laging hawakan nang maayos ang mga kagamitang pang-agham habang isinasagawa ang mga pagsubok na ito.',
    ],
  },
  'q2w1': {
    'en': [
      'The compound microscope magnifies objects that are too small to be seen by the eye alone. The English physicist Robert Hooke used one to look at cork, and the tiny pores he saw there are what we now call cells.',
      'Learn the parts and what each one does. You look through the eyepiece at the top, the objective lenses closest to the specimen do the main magnifying, the stage holds the slide in place with stage clips, the diaphragm varies how much light passes into the slide, and the illuminator at the base is the light source.',
      'Magnification is calculated by multiplying the magnification of the objective lens by the magnification of the eyepiece. Use the coarse adjustment knob first to bring the specimen into general focus and the fine adjustment knob to sharpen the image, and always carry the microscope by its arm.',
    ],
    'Filipino': [
      'Ang compound microscope ay nagpapalaki sa mga bagay na napakaliit upang makita ng mata lamang. Ginamit ito ng English physicist na si Robert Hooke upang tingnan ang cork, at ang maliliit na butas na nakita niya roon ang tinatawag nating cells ngayon.',
      'Kilalanin ang mga bahagi at ang gawain ng bawat isa. Sinisilip mo ang eyepiece sa itaas, ang objective lenses na pinakamalapit sa specimen ang pangunahing nagpapalaki, ang stage ang humahawak sa slide kasama ang stage clips, ang diaphragm ang nagbabago sa dami ng liwanag na dumadaan sa slide, at ang illuminator sa base ang pinagmumulan ng liwanag.',
      'Ang magnification ay nakukuha sa pagpaparami ng magnification ng objective lens sa magnification ng eyepiece. Gamitin muna ang coarse adjustment knob upang maging malinaw ang specimen at ang fine adjustment knob upang patalasin ang imahe, at palaging buhatin ang mikroskopyo sa arm nito.',
    ],
  },
  'q2w2': {
    'en': [
      'Cell theory has three parts. All organisms are made of cells, cells are the basic unit of life, and cells come from other cells that have already multiplied.',
      'Each organelle has its own work. The nucleus holds the genetic material and acts as the command center, the mitochondrion is known as the powerhouse because it supplies most of the cell\'s energy, the ribosomes are the site of protein synthesis, and the Golgi apparatus modifies, sorts, and packages proteins and lipids.',
      'Plant and animal cells share many of these parts, but the chloroplast is found in plant cells and not in animal cells, and only the plant cell has a cell wall, which provides structural support and protection. When you compare the two, look also at the vacuole, the centrioles, and the shape of the cell.',
    ],
    'Filipino': [
      'May tatlong bahagi ang cell theory. Ang lahat ng organismo ay binubuo ng mga selula, ang selula ang basic unit of life, at ang mga selula ay nagmumula sa ibang selulang dumami na.',
      'May sariling gawain ang bawat organelle. Ang nucleus ang naglalaman ng genetic material at siyang command center, ang mitochondrion ang tinatawag na powerhouse dahil ito ang nagbibigay ng halos lahat ng enerhiya ng selula, ang ribosomes ang pinaggagawaan ng protina, at ang Golgi apparatus ang nagbabago, nag-aayos, at nagbabalot ng mga protina at lipid.',
      'Marami sa mga bahaging ito ang magkapareho sa plant at animal cell, ngunit ang chloroplast ay matatagpuan sa plant cell at wala sa animal cell, at ang plant cell lamang ang may cell wall na nagbibigay ng suporta at proteksyon. Sa paghahambing ng dalawa, tingnan din ang vacuole, ang centrioles, at ang hugis ng selula.',
    ],
  },
  'q2w3': {
    'en': [
      'Some organisms are unicellular, which means they consist of a single cell, like bacteria. Others are multicellular, made up of many specialized cells working together, like a human being.',
      'Cells are also grouped as prokaryotic or eukaryotic. A prokaryotic cell has no nucleus, and its genetic material sits in a region called the nucleoid, while eukaryotic organisms such as dogs and mushrooms do have a nucleus. Both kinds of cells still contain DNA.',
      'Being multicellular brings specialized cells and the capacity to replace or repair damaged cells, which is why multicellular organisms usually live longer. Unicellular organisms are simpler, they adapt well to different environments, and they can reproduce asexually.',
    ],
    'Filipino': [
      'May mga organismong unicellular, ibig sabihin ay binubuo lamang ng iisang selula, tulad ng bacteria. Ang iba ay multicellular, binubuo ng maraming espesyalisadong selula na nagtutulungan, tulad ng tao.',
      'Ang mga selula ay inuuri rin bilang prokaryotic o eukaryotic. Ang prokaryotic cell ay walang nucleus, at ang genetic material nito ay nasa bahaging tinatawag na nucleoid, samantalang ang mga eukaryotic na organismo tulad ng aso at kabute ay may nucleus. Pareho pa ring may DNA ang dalawang uri ng selula.',
      'Ang pagiging multicellular ay nagbibigay ng espesyalisadong selula at ng kakayahang palitan o ayusin ang mga nasirang selula, kaya mas matagal mabuhay ang mga multicellular na organismo. Ang unicellular na organismo naman ay mas simple, madaling makibagay sa iba\'t ibang kapaligiran, at nakakapagparami nang asexually.',
    ],
  },
  'q2w4': {
    'en': [
      'Cells reproduce through two types of cell division, mitosis and meiosis. Mitosis divides the chromosomes of a cell into two identical daughter cells, and it produces the cells needed for growth, development, and tissue repair.',
      'Mitosis has four stages. In prophase the chromosomes condense and become visible, the nuclear envelope breaks up, and the spindle forms. In metaphase the chromosomes line up along the equator of the cell.',
      'In anaphase the shortening spindle fibers separate the chromosomes and move them to opposite sides of the cell. In telophase the nucleus reforms around each group of chromosomes, and then cytokinesis divides the cytoplasm, so that two separate cells are ready to repeat the process.',
    ],
    'Filipino': [
      'Ang mga selula ay dumarami sa dalawang uri ng cell division, ang mitosis at ang meiosis. Sa mitosis, ang chromosomes ng selula ay nahahati sa dalawang magkaparehong daughter cell, at dito nagmumula ang mga selulang kailangan sa paglaki, pag-unlad, at pag-aayos ng tissue.',
      'May apat na yugto ang mitosis. Sa prophase, ang chromosomes ay lumalapot at nagiging nakikita, nagkakawatak-watak ang nuclear envelope, at nabubuo ang spindle. Sa metaphase, pumipila ang chromosomes sa gitna o equator ng selula.',
      'Sa anaphase, ang umiikling spindle fibers ang naghihiwalay sa chromosomes at naghahatid sa kanila sa magkabilang dulo ng selula. Sa telophase, muling nabubuo ang nucleus sa paligid ng bawat pangkat ng chromosomes, at pagkatapos ay hinahati ng cytokinesis ang cytoplasm, kaya nabubuo ang dalawang hiwalay na selulang handang ulitin ang proseso.',
    ],
  },
  'q2w5': {
    'en': [
      'Sexual reproduction uses sex cells, which are also called gametes. The gametes are the egg cell and the sperm cell, and meiosis is the division that produces them with half the number of chromosomes.',
      'A human body cell carries forty six chromosomes, which is the diploid number, so a human sperm cell or egg cell carries only twenty three, which is the haploid number. A child receives one set of chromosomes from the mother and one set from the father.',
      'In fertilization, a female gamete and a male gamete fuse and form a zygote, a cell with a new genetic combination. This is how genetic information is passed on to offspring, and it is the reason sexual reproduction increases genetic variation.',
    ],
    'Filipino': [
      'Ang sexual reproduction ay gumagamit ng sex cells na tinatawag ding gametes. Ang gametes ay ang egg cell at ang sperm cell, at ang meiosis ang cell division na gumagawa sa kanila na may kalahati lamang ng bilang ng chromosomes.',
      'Ang body cell ng tao ay may apatnapu\'t anim na chromosomes, ito ang diploid number, kaya ang sperm cell o egg cell ng tao ay may dalawampu\'t tatlo lamang, ito ang haploid number. Ang anak ay tumatanggap ng isang set ng chromosomes mula sa ina at isang set mula sa ama.',
      'Sa fertilization, nagsasanib ang babae at lalaking gamete at nabubuo ang zygote, isang selulang may bagong kombinasyon ng genes. Ganito naipapasa ang genetic information sa anak, at ito ang dahilan kung bakit pinapataas ng sexual reproduction ang genetic variation.',
    ],
  },
  'q2w6': {
    'en': [
      'Asexual reproduction requires only one parent to produce offspring, and the offspring are genetic clones of that parent. Sexual reproduction requires two parents, so the offspring are not identical to either one.',
      'There are several types of asexual reproduction. Binary fission, budding, spore formation, fragmentation, where an organism breaks apart and each fragment develops into a new individual, and vegetative reproduction, the way one lily bulb becomes a whole colony of identical lilies.',
      'A key advantage is that large numbers of offspring can be produced very quickly, without needing to find a mate. The disadvantage is that the offspring are all identical, so a single event such as an extreme temperature can wipe out an entire colony.',
    ],
    'Filipino': [
      'Ang asexual reproduction ay nangangailangan lamang ng isang magulang upang makabuo ng anak, at ang mga anak ay genetic clones ng magulang na iyon. Ang sexual reproduction ay nangangailangan ng dalawang magulang, kaya hindi eksaktong kamukha ng alinman sa kanila ang anak.',
      'May ilang uri ng asexual reproduction. Ang binary fission, budding, spore formation, fragmentation kung saan nabibiyak ang organismo at ang bawat piraso ay nagiging bagong indibidwal, at ang vegetative reproduction, tulad ng isang lily bulb na nagiging isang buong kolonya ng magkakaparehong lily.',
      'Ang malaking bentahe nito ay ang napakabilis na pagdami ng anak nang hindi na kailangang maghanap ng kapareha. Ang disbentahe ay magkakapareho ang lahat ng anak, kaya kayang mapuksa ng iisang pangyayari tulad ng sobrang init o lamig ang buong kolonya.',
    ],
  },
  'q2w7': {
    'en': [
      'Ecology is the study of the relationships among organisms and their interaction with the environment. Organisms are affected by biotic factors, which are living, and by abiotic factors, which are non living, and the natural home of an organism is called its habitat.',
      'Biological organization arranges the levels of living things from the simplest to the most complex. It goes from atoms and molecules to organelles, then cells, tissues, organs, organ systems, and finally the whole organism.',
      'Beyond the organism the levels continue. Individuals of the same species form a population, populations of different species living and interacting in one area form a community, a community together with the non living factors it interacts with forms an ecosystem, and all of these together make up the biosphere.',
    ],
    'Filipino': [
      'Ang ecology ay ang pag-aaral ng ugnayan ng mga organismo at ng kanilang pakikipag-ugnayan sa kapaligiran. Ang mga organismo ay naaapektuhan ng biotic factors na buhay, at ng abiotic factors na hindi buhay, at ang likas na tirahan ng isang organismo ay tinatawag na habitat nito.',
      'Ang biological organization ay nag-aayos sa mga antas ng buhay mula sa pinakasimple hanggang sa pinakakomplikado. Nagsisimula ito sa atom at molecule, papunta sa organelle, selula, tissue, organ, organ system, at sa huli ay ang buong organismo.',
      'May mga karugtong pang antas higit sa organismo. Ang magkakauring indibidwal ay bumubuo ng population, ang magkakaibang population na magkasamang nakatira sa isang lugar ay bumubuo ng community, ang community kasama ang mga hindi buhay na salik ay bumubuo ng ecosystem, at ang lahat ng ito ay bumubuo ng biosphere.',
    ],
  },
  'q2w8': {
    'en': [
      'The ultimate source of energy on Earth is the sun. Plants are called producers because they convert solar energy into chemical energy in the form of food.',
      'A food chain shows the eating sequence, in simple terms what eats what, and how energy is transferred from one organism to another. A food web joins many food chains together, because in a real ecosystem an organism is usually part of more than one chain.',
      'Consumers are grouped as herbivores, carnivores, and omnivores, and decomposers such as bacteria break down the bodies of dead organisms. In an energy pyramid the levels are the producers, then the primary, secondary, and tertiary consumers, and in the end all the energy in the ecosystem is lost as heat.',
    ],
    'Filipino': [
      'Ang pinakapinagmumulan ng enerhiya sa Daigdig ay ang araw. Ang mga halaman ay tinatawag na producers dahil ginagawa nilang chemical energy na anyong pagkain ang solar energy.',
      'Ipinapakita ng food chain ang pagkakasunod-sunod ng pagkain, sa simpleng salita kung ano ang kumakain ng ano, at kung paano lumilipat ang enerhiya mula sa isang organismo patungo sa iba. Ang food web ay pinagdurugtong ang maraming food chain, dahil sa tunay na ecosystem ay kabilang ang isang organismo sa higit sa isang chain.',
      'Ang mga consumer ay inuuri bilang herbivores, carnivores, at omnivores, at ang mga decomposer tulad ng bacteria ang nagbubulok sa katawan ng mga patay na organismo. Sa energy pyramid, ang mga antas ay ang producers, sunod ang primary, secondary, at tertiary consumers, at sa huli ang lahat ng enerhiya sa ecosystem ay nawawala bilang init.',
    ],
  },
  'q3w1': {
    'en': [
      'A force is a push or a pull that acts on an object because of its interaction with another object. Remember that forces are always applied by one object on another object.',
      'A force can change the size or the shape of an object, it can make a stationary object move, it can speed up, slow down, or stop a moving object, and it can change the direction of a moving object.',
      'Forces are classified as contact forces, where the objects touch, such as pushing a cart or the tension in a string, and non contact forces, which act without touching, such as gravity, magnetic force, and electrostatic force. A spring balance may be used to measure the magnitude of a force, and the unit of force is the newton.',
    ],
    'Filipino': [
      'Ang force ay isang tulak o hila na kumikilos sa isang bagay dahil sa pakikipag-ugnayan nito sa ibang bagay. Tandaan na ang puwersa ay laging inilalapat ng isang bagay sa ibang bagay.',
      'Ang puwersa ay maaaring magpabago sa laki o hugis ng isang bagay, makapagpagalaw sa nakatigil na bagay, makapagpabilis, makapagpabagal, o makapagpahinto sa gumagalaw na bagay, at makapagpabago sa direksyon ng gumagalaw na bagay.',
      'Ang mga puwersa ay inuuri bilang contact forces, kung saan nagkakadikit ang mga bagay, tulad ng pagtulak ng kariton o ang tension sa isang lubid, at non-contact forces na kumikilos nang walang dikitan, tulad ng gravity, magnetic force, at electrostatic force. Maaaring gamitin ang spring balance upang sukatin ang lakas ng puwersa, at ang yunit ng puwersa ay ang newton.',
    ],
  },
  'q3w2': {
    'en': [
      'Physical quantities can be classified as scalars or vectors. A scalar measures magnitude or size only, while a vector has both magnitude and direction, and force is a vector quantity.',
      'A force is represented using an arrow. The length of the arrow shows the magnitude of the force, so the longer the arrow the larger the force, and the arrowhead points in the direction of the force.',
      'A free body diagram represents all the forces acting on one object, which helps us analyze how each force affects its state of motion. For a book resting on a table, the forces are its weight, which pulls it down because of the Earth\'s gravity, and the normal or support force from the table pushing up on it.',
    ],
    'Filipino': [
      'Ang mga physical quantity ay maaaring uriin bilang scalar o vector. Ang scalar ay sumusukat lamang ng laki o magnitude, samantalang ang vector ay may magnitude at direksyon, at ang force ay isang vector quantity.',
      'Ang puwersa ay iginuguhit gamit ang arrow. Ang haba ng arrow ang nagpapakita ng lakas ng puwersa, kaya mas mahaba ang arrow, mas malaki ang puwersa, at ang dulo ng arrow ang nagtuturo sa direksyon nito.',
      'Ang free body diagram ay kumakatawan sa lahat ng puwersang kumikilos sa isang bagay, at tumutulong ito upang suriin kung paano naaapektuhan ng bawat puwersa ang galaw nito. Sa isang aklat na nakapatong sa mesa, ang mga puwersa ay ang weight nito na humihila pababa dahil sa gravity ng Daigdig, at ang normal o support force ng mesa na tumutulak pataas.',
    ],
  },
  'q3w3': {
    'en': [
      'Forces acting on an object are balanced when they have the same magnitude and act in opposite directions. When the forces are balanced, the object stays at rest, or it keeps moving at a constant speed in the same direction.',
      'Forces are unbalanced when they do not cancel out, and then the object changes its speed, its direction, or both. A freely falling fruit and a car that is speeding up are everyday examples of unbalanced forces.',
      'Illustrate the forces in a free body diagram first, then work out the direction of the net force to predict the state of motion. A box resting on an inclined plane, a person standing still, and an object moving at constant velocity are all examples of balanced forces.',
    ],
    'Filipino': [
      'Ang mga puwersang kumikilos sa isang bagay ay balanced kapag magkapareho ang lakas at magkasalungat ang direksyon. Kapag balanced ang mga puwersa, ang bagay ay nananatiling nakatigil, o patuloy na gumagalaw sa pare-parehong bilis at direksyon.',
      'Unbalanced naman ang mga puwersa kapag hindi sila nagkakansela, at dito nagbabago ang bilis, ang direksyon, o pareho. Ang bumabagsak na prutas at ang kotseng bumibilis ay pang-araw-araw na halimbawa ng unbalanced forces.',
      'Iguhit muna ang mga puwersa sa free body diagram, pagkatapos ay tukuyin ang direksyon ng net force upang mahulaan ang galaw ng bagay. Ang kahon na nakapatong sa inclined plane, ang taong nakatayo nang hindi gumagalaw, at ang bagay na gumagalaw sa constant velocity ay pawang mga halimbawa ng balanced forces.',
    ],
  },
  'q3w4': {
    'en': [
      'Motion is relative. An object is in motion when its position changes with respect to a chosen reference point, so as you walk from your house to school you are moving with respect to your house, but you are at rest with respect to your own shoes.',
      'There are three conditions of motion. A reference point or starting position, a change in position, and a time interval in which that change happens.',
      'Distance is a scalar quantity, the actual length of the path covered. Displacement is a vector quantity, the shortest distance from the initial position to the final position, together with its direction. If you walk seventy meters east to school and then seventy meters west back home, your distance is one hundred forty meters but your displacement is zero.',
    ],
    'Filipino': [
      'Ang galaw ay relative. Ang isang bagay ay gumagalaw kapag nagbabago ang posisyon nito kaugnay ng napiling reference point, kaya habang naglalakad ka mula bahay patungong paaralan ay gumagalaw ka kaugnay ng inyong bahay, ngunit nakatigil ka kaugnay ng sarili mong sapatos.',
      'May tatlong kondisyon ang galaw. Isang reference point o panimulang posisyon, isang pagbabago sa posisyon, at isang time interval kung kailan nangyari ang pagbabago.',
      'Ang distance ay scalar quantity, ang aktuwal na haba ng daanang tinahak. Ang displacement ay vector quantity, ang pinakamaikling layo mula sa panimula hanggang sa huling posisyon, kasama ang direksyon nito. Kung maglalakad ka ng pitumpung metro pasilangan patungong paaralan at pitumpung metro pakanluran pauwi, ang distance mo ay isang daan at apatnapung metro ngunit zero ang displacement mo.',
    ],
  },
  'q3w5': {
    'en': [
      'Speed is a measure of how fast something is moving. It is the distance covered per unit of time, and it is a scalar quantity because it does not include direction.',
      'Velocity is a vector quantity, because it describes both how fast and in which direction an object is moving. The formula is almost the same as speed, except that displacement is used instead of distance.',
      'Average speed is the total distance divided by the total time for the whole trip, while instantaneous speed is how fast an object is moving at one particular moment. An object that moves in a specific direction at a constant speed is in uniform motion.',
    ],
    'Filipino': [
      'Ang speed ay sukat kung gaano kabilis gumagalaw ang isang bagay. Ito ang distance na natatahak sa bawat yunit ng oras, at ito ay scalar quantity dahil walang kasamang direksyon.',
      'Ang velocity ay vector quantity, dahil inilalarawan nito kung gaano kabilis at kung saang direksyon gumagalaw ang bagay. Halos pareho lang ang pormula nito sa speed, maliban na displacement ang ginagamit sa halip na distance.',
      'Ang average speed ay ang kabuuang distance na hinati sa kabuuang oras ng buong biyahe, samantalang ang instantaneous speed ay kung gaano kabilis gumagalaw ang bagay sa isang partikular na sandali. Ang bagay na gumagalaw sa tiyak na direksyon at pare-parehong bilis ay nasa uniform motion.',
    ],
  },
  'q3w6': {
    'en': [
      'The motion of an object can be described with a line graph. In a distance time graph, the total distance moved is plotted against the time, but this graph does not tell us the direction.',
      'The slope of a distance time graph represents the speed of the object. In a displacement time graph the position of the object is plotted against time, and there the slope represents the velocity.',
      'Read the line carefully. A steeper line means faster motion, a horizontal line has zero slope and means the object is at rest, and a negative slope means the object is moving in the opposite direction. When the slope is the same over every interval, the object has uniform motion.',
    ],
    'Filipino': [
      'Maaaring ilarawan ang galaw ng isang bagay gamit ang line graph. Sa distance time graph, ang kabuuang distance na natahak ay iginuguhit laban sa oras, ngunit hindi ipinapakita ng graph na ito ang direksyon.',
      'Ang slope ng distance time graph ang kumakatawan sa speed ng bagay. Sa displacement time graph naman ay ang posisyon ng bagay ang iginuguhit laban sa oras, at doon ang slope ang kumakatawan sa velocity.',
      'Basahin nang maigi ang linya. Ang mas matarik na linya ay nangangahulugang mas mabilis na galaw, ang pahalang na linya ay may zero slope at nangangahulugang nakatigil ang bagay, at ang negatibong slope ay nangangahulugang pabalik ang direksyon ng galaw. Kapag pare-pareho ang slope sa bawat interval, ang bagay ay nasa uniform motion.',
    ],
  },
  'q3w7': {
    'en': [
      'Heat is a transfer of energy due to a difference in temperature, and it always flows from a region of higher temperature to a region of lower temperature. The unit of heat in the International System of Units is the joule.',
      'Temperature is the degree of hotness or coldness of an object, and it is a measure of the average kinetic energy of the particles in a substance. Its unit in the International System is the kelvin, although Celsius and Fahrenheit are also commonly used scales.',
      'Materials are classified by how well they let heat pass through. Conductors have high thermal conductivity, so they make heat transfer easy, while insulators have low thermal conductivity and are used to reduce heat transfer.',
    ],
    'Filipino': [
      'Ang heat ay paglipat ng enerhiya dahil sa pagkakaiba ng temperatura, at ito ay laging dumadaloy mula sa bahaging mas mataas ang temperatura patungo sa bahaging mas mababa. Ang yunit ng heat sa International System of Units ay ang joule.',
      'Ang temperatura ay ang antas ng init o lamig ng isang bagay, at ito ay sukat ng average kinetic energy ng mga partikula sa isang sangkap. Ang yunit nito sa International System ay ang kelvin, bagaman karaniwan ding gamitin ang Celsius at Fahrenheit.',
      'Ang mga materyal ay inuuri ayon sa kung gaano nila pinadadaan ang init. Ang conductors ay may mataas na thermal conductivity kaya madali silang dinadaanan ng init, samantalang ang insulators ay may mababang thermal conductivity at ginagamit upang bawasan ang paglipat ng init.',
    ],
  },
  'q3w8': {
    'en': [
      'There are three methods of heat transfer. These are conduction, convection, and radiation.',
      'In conduction, heat travels through a material by direct contact. When one end of a metal spoon is held over a flame, the atoms of the spoon vibrate faster and collide more strongly with one another, so the heat and the rise in temperature travel along the spoon to the other end.',
      'In convection, heat is carried by a moving liquid or gas, because hot water is less dense and rises while the denser cold water sinks, which is why cooling appliances are placed in high parts of a room. In radiation, heat travels as waves that need no material to pass through, and the color of a surface affects how it takes in and gives off that heat.',
    ],
    'Filipino': [
      'May tatlong paraan ng paglipat ng init. Ito ay ang conduction, convection, at radiation.',
      'Sa conduction, ang init ay dumadaan sa materyal sa pamamagitan ng direktang dikit. Kapag ang isang dulo ng kutsarang bakal ay inilagay sa apoy, mas mabilis na gumagalaw ang mga atom ng kutsara at mas malakas silang nagbabanggaan, kaya ang init at ang pagtaas ng temperatura ay naglalakbay sa kabilang dulo ng kutsara.',
      'Sa convection, ang init ay dala ng gumagalaw na likido o gas, dahil ang mainit na tubig ay mas magaan o less dense kaya pumapaitaas, samantalang ang mas siksik na malamig na tubig ay lumulubog, kaya ang mga cooling appliance ay inilalagay sa mataas na bahagi ng silid. Sa radiation, ang init ay naglalakbay bilang mga alon na hindi nangangailangan ng materyal na daanan, at ang kulay ng isang ibabaw ay nakakaapekto sa kung paano nito tinatanggap at pinapakawalan ang init na iyon.',
    ],
  },
};
