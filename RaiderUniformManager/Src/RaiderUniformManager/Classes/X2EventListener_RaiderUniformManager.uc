//---------------------------------------------------------------------------------------
//  FILE:   X2EventListener_RaiderUniformManager.uc                                    
//
//	CREATED BY RustyDios
//           
//	File created	21/08/20	12:00
//	LAST UPDATED    19/09/20	12:20
//  
//	USES A HIGHLANDER HOOK TO CHANGE THE UNIT APPEARANCE POST SPAWN
//
//---------------------------------------------------------------------------------------
class X2EventListener_RaiderUniformManager extends X2EventListener config(RaiderCustomization);

//////////////////////////////////////////////////
//  STRUCT FOR CONFIG FILE
/////////////////////////////////////////////////

struct RaiderCosmetics
{
	var name RaiderTemplateName;    // class this is used for
	var int	 iGender;               //use eGender_Male or eGender_Female
	var name Torso;
    var name TorsoDeco;
	var name Arms;
   	var name Legs;
	var name Thighs; 
	var name Shins;
	var name LeftArm;
    var name LeftArmDeco;
	var name LeftForeArm;
    var name Tattoo_LeftArm;
	var name RightArm;
	var name RightArmDeco;
	var name RightForeArm;
    var name Tattoo_RightArm;
    var int TattooTint;
	var name Helmet;
	var name FacePropUpper;
	var name FacePropLower;
    var int EyeColor;
    var int HairColor;
    var name Haircut;
    var name Beard;
    var name FacePaint;
    var int WeaponTint;
    var name WeaponPattern;
    var int ArmorTint;
    var int ArmorTintSecondary;
    var name Pattern;
   	var name Voice;
	var name Flag;
};

var config array<RaiderCosmetics> RaiderAppearances;
var config bool bEnableRUMLog, bSkirmishAppearanceTesting;

//////////////////////////////////////////////////
//  CREATE TEMPLATES
/////////////////////////////////////////////////

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(Create_RaiderUniformManager_USP());
	Templates.AddItem(Create_RaiderUniformManager_UBP());

	return Templates;
}

/////////////////////////////////////////////////////////////
//  LISTENER TEMPLATES 'UNITSPAWNED' && 'ONUNITBEGINPLAY'
////////////////////////////////////////////////////////////

//this catches units from the drop unit command as OnUnitBeginPlay will state no unit ID...
static function CHEventListenerTemplate Create_RaiderUniformManager_USP()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'RaiderUniformManager_USP');

	Template.RegisterInStrategy = false;
	Template.RegisterInTactical = true;

	Template.AddCHEvent('UnitSpawned', SwapRaiderUniform, ELD_Immediate);

	return Template;
}

//this catches units on the start of mission by natural spawn/sitrep spawn ... 
static function CHEventListenerTemplate Create_RaiderUniformManager_UBP()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'RaiderUniformManager_UBP');

	Template.RegisterInStrategy = false;
	Template.RegisterInTactical = true;

	Template.AddCHEvent('OnUnitBeginPlay', SwapRaiderUniform, ELD_Immediate);

	return Template;
}

//////////////////////////////////////////////////
//  ELR - FIND AND MATCH FUNCS
/////////////////////////////////////////////////

static protected function EventListenerReturn SwapRaiderUniform(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComGameState_Unit    RaiderUnit_State;

    local XGCharacterGenerator     CharGen;
    local TSoldier                 kSoldier;
	local RaiderCosmetics          PossibleAppearance;

	local array<XComGameState_Unit> CharacterPool;
    local int cp;
    local bool bWasSource;

   	`LOG("========================= RUM BEGUN ==============================================", default.bEnableRUMLog ,'RaiderUniformManager');

    RaiderUnit_State = XComGameState_Unit(EventData);

    //somehow we have no unit ? check event source
    if (RaiderUnit_State == none)
    {
        RaiderUnit_State = XComGameState_Unit(EventSource);
        bWasSource = true;

        //...we still have no unit... ABORT
        if (RaiderUnit_State == none)
        {
            `LOG("ABORTED :: No UNIT passed in ID !! " @Event , default.bEnableRUMLog ,'RaiderUniformManager');
           	`LOG("========================= RUM ENDED ==============================================", default.bEnableRUMLog ,'RaiderUniformManager');
            return ELR_NoInterrupt;
        }
    }

    `LOG("FOUND UNIT :: "$RaiderUnit_State.GetMyTemplateName() @RaiderUnit_State.GetName(eNameType_FullNick) @" :: Was EventSource :: " $bWasSource @" :: Event :: " $Event, default.bEnableRUMLog ,'RaiderUniformManager');
	`LOG("CHECK TEAM :: "$!default.bSkirmishAppearanceTesting @" :: " $RaiderUnit_State.GetMyTemplateName() @RaiderUnit_State.GetName(eNameType_FullNick) @" :: IS ON TEAM :: " $GetTeamString(RaiderUnit_State.GetTeam() ), default.bEnableRUMLog ,'RaiderUniformManager');

    //IGNORE for XCOM, ADVENT-ALIENS, CIVS and LOST ... we just want eTeam_Resistance (for RHI), eTeam_One (for Rebellious Factions) or eTeam_Two (Raider Factions)
    //if( (RaiderUnit_State.GetTeam() != eTeam_Resistance ||  RaiderUnit_State.GetTeam() != eTeam_One || RaiderUnit_State.GetTeam() != eTeam_Two) && !default.bSkirmishAppearanceTesting)
    if( (RaiderUnit_State.GetTeam() == eTeam_XCom || RaiderUnit_State.GetTeam() == eTeam_Alien || RaiderUnit_State.GetTeam() == eTeam_Neutral || RaiderUnit_State.GetTeam() == eTeam_TheLost || RaiderUnit_State.GetTeam() == eTeam_None) && !default.bSkirmishAppearanceTesting)
    {
		`LOG("ABORTED :: WRONG TEAM FOR RUM " , default.bEnableRUMLog ,'RaiderUniformManager');
        `LOG("========================= RUM ENDED ==============================================", default.bEnableRUMLog ,'RaiderUniformManager');
        return ELR_NoInterrupt;
    }

    //we have a good unit so we'll continue .... create the generator for the unit
    CharGen = `XCOMGRI.Spawn(RaiderUnit_State.GetMyTemplate().CharacterGeneratorClass);

    //create a new doll to store data temporarily
    kSoldier = CharGen.CreateTSoldierFromUnit(RaiderUnit_State, GameState);
    
    if (kSoldier.kAppearance.iGender == eGender_Male) //it was birthed a boy 
    {
        //check the config for new appearances
        foreach default.RaiderAppearances(PossibleAppearance)
        {
            //match entries to config, skip everything else
            if( PossibleAppearance.RaiderTemplateName == RaiderUnit_State.GetMyTemplateName()  && PossibleAppearance.iGender == eGender_Male)
            {
                //the appearance slot                   =   check if changed                            ?   no change, keep original                :   yes change, this is new
                kSoldier.kAppearance.nmTorso            = (PossibleAppearance.Torso == '')              ? kSoldier.kAppearance.nmTorso              : PossibleAppearance.Torso;
                kSoldier.kAppearance.nmTorsoDeco        = (PossibleAppearance.TorsoDeco == '')          ? kSoldier.kAppearance.nmTorsoDeco          : PossibleAppearance.TorsoDeco;
                kSoldier.kAppearance.nmArms             = (PossibleAppearance.Arms == '')               ? kSoldier.kAppearance.nmArms               : PossibleAppearance.Arms;
                kSoldier.kAppearance.nmLegs             = (PossibleAppearance.Legs == '')               ? kSoldier.kAppearance.nmLegs               : PossibleAppearance.Legs;
                kSoldier.kAppearance.nmThighs           = (PossibleAppearance.Thighs == '')             ? kSoldier.kAppearance.nmThighs             : PossibleAppearance.Thighs;
                kSoldier.kAppearance.nmShins            = (PossibleAppearance.Shins == '')              ? kSoldier.kAppearance.nmShins              : PossibleAppearance.Shins;
                kSoldier.kAppearance.nmLeftArm          = (PossibleAppearance.LeftArm == '')            ? kSoldier.kAppearance.nmLeftArm            : PossibleAppearance.LeftArm;
                kSoldier.kAppearance.nmLeftForearm      = (PossibleAppearance.LeftForeArm == '')        ? kSoldier.kAppearance.nmLeftForearm        : PossibleAppearance.LeftForeArm;
                kSoldier.kAppearance.nmLeftArmDeco      = (PossibleAppearance.LeftArmDeco == '')        ? kSoldier.kAppearance.nmLeftArmDeco        : PossibleAppearance.LeftArmDeco;
                kSoldier.kAppearance.nmTattoo_LeftArm   = (PossibleAppearance.Tattoo_LeftArm == '')     ? kSoldier.kAppearance.nmTattoo_LeftArm     : PossibleAppearance.Tattoo_LeftArm;
                kSoldier.kAppearance.nmRightArm         = (PossibleAppearance.RightArm == '')           ? kSoldier.kAppearance.nmRightArm           : PossibleAppearance.RightArm;
                kSoldier.kAppearance.nmRightForearm     = (PossibleAppearance.RightForeArm == '')       ? kSoldier.kAppearance.nmRightForearm       : PossibleAppearance.RightForeArm;
                kSoldier.kAppearance.nmRightArmDeco     = (PossibleAppearance.RightArmDeco == '')       ? kSoldier.kAppearance.nmRightArmDeco       : PossibleAppearance.RightArmDeco;
                kSoldier.kAppearance.nmTattoo_RightArm  = (PossibleAppearance.Tattoo_RightArm == '')    ? kSoldier.kAppearance.nmTattoo_RightArm    : PossibleAppearance.Tattoo_RightArm;
                kSoldier.kAppearance.iTattooTint        = (PossibleAppearance.TattooTint == 0)          ? kSoldier.kAppearance.iTattooTint          : PossibleAppearance.TattooTint;
                kSoldier.kAppearance.nmHelmet           = (PossibleAppearance.Helmet == '')             ? kSoldier.kAppearance.nmHelmet             : PossibleAppearance.Helmet;
                kSoldier.kAppearance.nmFacePropUpper    = (PossibleAppearance.FacePropUpper == '')      ? kSoldier.kAppearance.nmFacePropUpper      : PossibleAppearance.FacePropUpper;
                kSoldier.kAppearance.nmFacePropLower    = (PossibleAppearance.FacePropLower == '')      ? kSoldier.kAppearance.nmFacePropLower      : PossibleAppearance.FacePropLower;
                kSoldier.kAppearance.iEyeColor          = (PossibleAppearance.EyeColor == 0)            ? kSoldier.kAppearance.iEyeColor            : PossibleAppearance.EyeColor;
                kSoldier.kAppearance.iHairColor         = (PossibleAppearance.HairColor == 0)           ? kSoldier.kAppearance.iHairColor           : PossibleAppearance.HairColor;
                kSoldier.kAppearance.nmHaircut          = (PossibleAppearance.Haircut == '')            ? kSoldier.kAppearance.nmHaircut            : PossibleAppearance.Haircut;
                kSoldier.kAppearance.nmBeard            = (PossibleAppearance.Beard == '')              ? kSoldier.kAppearance.nmBeard              : PossibleAppearance.Beard;
                kSoldier.kAppearance.nmFacePaint        = (PossibleAppearance.FacePaint == '')          ? kSoldier.kAppearance.nmFacePaint          : PossibleAppearance.FacePaint;
                kSoldier.kAppearance.iWeaponTint        = (PossibleAppearance.WeaponTint == 0)          ? kSoldier.kAppearance.iWeaponTint          : PossibleAppearance.WeaponTint;
                kSoldier.kAppearance.nmWeaponPattern    = (PossibleAppearance.WeaponPattern == '')      ? kSoldier.kAppearance.nmWeaponPattern      : PossibleAppearance.WeaponPattern;
                kSoldier.kAppearance.iArmorTint         = (PossibleAppearance.ArmorTint == 0)           ? kSoldier.kAppearance.iArmorTint           : PossibleAppearance.ArmorTint;
                kSoldier.kAppearance.iArmorTintSecondary= (PossibleAppearance.ArmorTintSecondary == 0)  ? kSoldier.kAppearance.iArmorTintSecondary  : PossibleAppearance.ArmorTintSecondary;
                kSoldier.kAppearance.nmPatterns         = (PossibleAppearance.Pattern == '')            ? kSoldier.kAppearance.nmPatterns           : PossibleAppearance.Pattern;
                kSoldier.kAppearance.nmVoice            = (PossibleAppearance.Voice == '')              ? kSoldier.kAppearance.nmVoice              : PossibleAppearance.Voice;
                kSoldier.kAppearance.nmFlag             = (PossibleAppearance.Flag == '')               ? kSoldier.kAppearance.nmFlag               : PossibleAppearance.Flag;              //yes these are meant to match
                kSoldier.nmCountry						= (PossibleAppearance.Flag == '')               ? kSoldier.kAppearance.nmFlag               : PossibleAppearance.Flag;              //yes these are meant to match
                //kSoldier.kAppearance.bGhostPawn       = (PossibleAppearance.bGhost == '')             ? kSoldier.kAppearance.bGhostPawn           : PossibleAppearance.bGhost;            //reserved for templar ghosts! 
                //kSoldier.kAppearance.nmEye            = (PossibleAppearance.Eyes == '')               ? kSoldier.kAppearance.nmEye                : PossibleAppearance.Eyes;              //decided not to allow
                //kSoldier.kAppearance.nmTeeth          = (PossibleAppearance.Teeth == '')              ? kSoldier.kAppearance.nmTeeth              : PossibleAppearance.Teeth;             //decided not to allow
                //kSoldier.kAppearance.nmScars          = (PossibleAppearance.Scars == '')              ? kSoldier.kAppearance.nmScars              : PossibleAppearance.Scars;             //decided not to allow
                //kSoldier.kAppearance.nmTorso_Underlay = (PossibleAppearance.TorsoUnderlay == '')      ? kSoldier.kAppearance.nmTorso_Underlay     : PossibleAppearance.TorsoUnderlay;     //decided not to allow
                //kSoldier.kAppearance.nmArms_Underlay  = (PossibleAppearance.ArmsUnderlay == '')       ? kSoldier.kAppearance.nmArms_Underlay      : PossibleAppearance.ArmsUnderlay;      //decided not to allow
                //kSoldier.kAppearance.nmLegs_Underlay  = (PossibleAppearance.LegsUnderlay == '')       ? kSoldier.kAppearance.nmLegs_Underlay      : PossibleAppearance.LegsUnderlay;      //decided not to allow

                //SUCCESS!!
   				`LOG("UNIT APPEARANCE FOUND :: Config Male :: " $RaiderUnit_State.GetMyTemplateName(), default.bEnableRUMLog ,'RaiderUniformManager');
                SwapUniform(RaiderUnit_State, kSoldier, CharGen, GameState);
                return ELR_NoInterrupt;
            }
        }
    }
    else if (kSoldier.kAppearance.iGender == eGender_Female)//it was birthed a girl
    {
        //check the config for new appearances
        foreach default.RaiderAppearances(PossibleAppearance)
        {
            //match entries to config, skip everything else
            if( PossibleAppearance.RaiderTemplateName == RaiderUnit_State.GetMyTemplateName()  && PossibleAppearance.iGender == eGender_Female)
            {
                //the appearance slot                   =   check if changed                            ?   no change, keep original                :   yes change, this is new
                kSoldier.kAppearance.nmTorso            = (PossibleAppearance.Torso == '')              ? kSoldier.kAppearance.nmTorso              : PossibleAppearance.Torso;
                kSoldier.kAppearance.nmTorsoDeco        = (PossibleAppearance.TorsoDeco == '')          ? kSoldier.kAppearance.nmTorsoDeco          : PossibleAppearance.TorsoDeco;
                kSoldier.kAppearance.nmArms             = (PossibleAppearance.Arms == '')               ? kSoldier.kAppearance.nmArms               : PossibleAppearance.Arms;
                kSoldier.kAppearance.nmLegs             = (PossibleAppearance.Legs == '')               ? kSoldier.kAppearance.nmLegs               : PossibleAppearance.Legs;
                kSoldier.kAppearance.nmThighs           = (PossibleAppearance.Thighs == '')             ? kSoldier.kAppearance.nmThighs             : PossibleAppearance.Thighs;
                kSoldier.kAppearance.nmShins            = (PossibleAppearance.Shins == '')              ? kSoldier.kAppearance.nmShins              : PossibleAppearance.Shins;
                kSoldier.kAppearance.nmLeftArm          = (PossibleAppearance.LeftArm == '')            ? kSoldier.kAppearance.nmLeftArm            : PossibleAppearance.LeftArm;
                kSoldier.kAppearance.nmLeftForearm      = (PossibleAppearance.LeftForeArm == '')        ? kSoldier.kAppearance.nmLeftForearm        : PossibleAppearance.LeftForeArm;
                kSoldier.kAppearance.nmLeftArmDeco      = (PossibleAppearance.LeftArmDeco == '')        ? kSoldier.kAppearance.nmLeftArmDeco        : PossibleAppearance.LeftArmDeco;
                kSoldier.kAppearance.nmTattoo_LeftArm   = (PossibleAppearance.Tattoo_LeftArm == '')     ? kSoldier.kAppearance.nmTattoo_LeftArm     : PossibleAppearance.Tattoo_LeftArm;
                kSoldier.kAppearance.nmRightArm         = (PossibleAppearance.RightArm == '')           ? kSoldier.kAppearance.nmRightArm           : PossibleAppearance.RightArm;
                kSoldier.kAppearance.nmRightForearm     = (PossibleAppearance.RightForeArm == '')       ? kSoldier.kAppearance.nmRightForearm       : PossibleAppearance.RightForeArm;
                kSoldier.kAppearance.nmRightArmDeco     = (PossibleAppearance.RightArmDeco == '')       ? kSoldier.kAppearance.nmRightArmDeco       : PossibleAppearance.RightArmDeco;
                kSoldier.kAppearance.nmTattoo_RightArm  = (PossibleAppearance.Tattoo_RightArm == '')    ? kSoldier.kAppearance.nmTattoo_RightArm    : PossibleAppearance.Tattoo_RightArm;
                kSoldier.kAppearance.iTattooTint        = (PossibleAppearance.TattooTint == 0)          ? kSoldier.kAppearance.iTattooTint          : PossibleAppearance.TattooTint;
                kSoldier.kAppearance.nmHelmet           = (PossibleAppearance.Helmet == '')             ? kSoldier.kAppearance.nmHelmet             : PossibleAppearance.Helmet;
                kSoldier.kAppearance.nmFacePropUpper    = (PossibleAppearance.FacePropUpper == '')      ? kSoldier.kAppearance.nmFacePropUpper      : PossibleAppearance.FacePropUpper;
                kSoldier.kAppearance.nmFacePropLower    = (PossibleAppearance.FacePropLower == '')      ? kSoldier.kAppearance.nmFacePropLower      : PossibleAppearance.FacePropLower;
                kSoldier.kAppearance.iEyeColor          = (PossibleAppearance.EyeColor == 0)            ? kSoldier.kAppearance.iEyeColor            : PossibleAppearance.EyeColor;
                kSoldier.kAppearance.iHairColor         = (PossibleAppearance.HairColor == 0)           ? kSoldier.kAppearance.iHairColor           : PossibleAppearance.HairColor;
                kSoldier.kAppearance.nmHaircut          = (PossibleAppearance.Haircut == '')            ? kSoldier.kAppearance.nmHaircut            : PossibleAppearance.Haircut;
                kSoldier.kAppearance.nmBeard            = (PossibleAppearance.Beard == '')              ? kSoldier.kAppearance.nmBeard              : PossibleAppearance.Beard;
                kSoldier.kAppearance.nmFacePaint        = (PossibleAppearance.FacePaint == '')          ? kSoldier.kAppearance.nmFacePaint          : PossibleAppearance.FacePaint;
                kSoldier.kAppearance.iWeaponTint        = (PossibleAppearance.WeaponTint == 0)          ? kSoldier.kAppearance.iWeaponTint          : PossibleAppearance.WeaponTint;
                kSoldier.kAppearance.nmWeaponPattern    = (PossibleAppearance.WeaponPattern == '')      ? kSoldier.kAppearance.nmWeaponPattern      : PossibleAppearance.WeaponPattern;
                kSoldier.kAppearance.iArmorTint         = (PossibleAppearance.ArmorTint == 0)           ? kSoldier.kAppearance.iArmorTint           : PossibleAppearance.ArmorTint;
                kSoldier.kAppearance.iArmorTintSecondary= (PossibleAppearance.ArmorTintSecondary == 0)  ? kSoldier.kAppearance.iArmorTintSecondary  : PossibleAppearance.ArmorTintSecondary;
                kSoldier.kAppearance.nmPatterns         = (PossibleAppearance.Pattern == '')            ? kSoldier.kAppearance.nmPatterns           : PossibleAppearance.Pattern;
                kSoldier.kAppearance.nmVoice            = (PossibleAppearance.Voice == '')              ? kSoldier.kAppearance.nmVoice              : PossibleAppearance.Voice;
                kSoldier.kAppearance.nmFlag             = (PossibleAppearance.Flag == '')               ? kSoldier.kAppearance.nmFlag               : PossibleAppearance.Flag;              //yes these are meant to match
                kSoldier.nmCountry						= (PossibleAppearance.Flag == '')               ? kSoldier.kAppearance.nmFlag               : PossibleAppearance.Flag;              //yes these are meant to match
                //kSoldier.kAppearance.bGhostPawn       = (PossibleAppearance.bGhost == '')             ? kSoldier.kAppearance.bGhostPawn           : PossibleAppearance.bGhost;            //reserved for templar ghosts! 
                //kSoldier.kAppearance.nmEye            = (PossibleAppearance.Eyes == '')               ? kSoldier.kAppearance.nmEye                : PossibleAppearance.Eyes;              //decided not to allow
                //kSoldier.kAppearance.nmTeeth          = (PossibleAppearance.Teeth == '')              ? kSoldier.kAppearance.nmTeeth              : PossibleAppearance.Teeth;             //decided not to allow
                //kSoldier.kAppearance.nmScars          = (PossibleAppearance.Scars == '')              ? kSoldier.kAppearance.nmScars              : PossibleAppearance.Scars;             //decided not to allow
                //kSoldier.kAppearance.nmTorso_Underlay = (PossibleAppearance.TorsoUnderlay == '')      ? kSoldier.kAppearance.nmTorso_Underlay     : PossibleAppearance.TorsoUnderlay;     //decided not to allow
                //kSoldier.kAppearance.nmArms_Underlay  = (PossibleAppearance.ArmsUnderlay == '')       ? kSoldier.kAppearance.nmArms_Underlay      : PossibleAppearance.ArmsUnderlay;      //decided not to allow
                //kSoldier.kAppearance.nmLegs_Underlay  = (PossibleAppearance.LegsUnderlay == '')       ? kSoldier.kAppearance.nmLegs_Underlay      : PossibleAppearance.LegsUnderlay;      //decided not to allow

                //SUCCESS!!
   				`LOG("UNIT APPEARANCE FOUND :: Config Female :: " $RaiderUnit_State.GetMyTemplateName(), default.bEnableRUMLog ,'RaiderUniformManager');
                SwapUniform(RaiderUnit_State, kSoldier, CharGen, GameState);
                return ELR_NoInterrupt;
            }
        }
    }
    else    //we don't know wtf it is ... should never run, but just in case
    {
   		`LOG("ABORTED :: GENDER WAS UNKNOWN :: " $RaiderUnit_State.GetMyTemplateName() @" :: " $GetGenderString(kSoldier.kAppearance.iGender), default.bEnableRUMLog ,'RaiderUniformManager');
        
        //destroy any lingering char gens and kSoldiers ?
        if( CharGen != none )   {   CharGen.Destroy(); }

        `LOG("========================= RUM ENDED ==============================================", default.bEnableRUMLog ,'RaiderUniformManager');
        return ELR_NoInterrupt;
    }

    // insert override appearance from pool dark VIPs
	CharacterPool = `CHARACTERPOOLMGR.CharacterPool;
	for(cp = 0; cp <= CharacterPool.length; cp++)
    {
        //only care if they have been marked as Dark VIP
		if (CharacterPool[cp].bAllowedTypeDarkVIP)
		{
            //check the template name is in thier name, mod page will dictate 'nickname' but can be anywhere in name honestly
			if (InStr(CharacterPool[cp].GetName(eNameType_FullNick), RaiderUnit_State.GetMyTemplateName() ) != INDEX_NONE ) 
			{
                //match gender
				if (kSoldier.kAppearance.iGender == CharacterPool[cp].kAppearance.iGender)
				{
					kSoldier.kAppearance = CharacterPool[cp].kAppearance;

                    //SUCCESS!!
					`LOG("UNIT APPEARANCE FOUND :: Pool :: " $RaiderUnit_State.GetMyTemplateName() @" :: Pool :: " $CharacterPool[cp].GetName(eNameType_FullNick), default.bEnableRUMLog ,'RaiderUniformManager');
                    SwapUniform(RaiderUnit_State, kSoldier, CharGen, GameState);
                    return ELR_NoInterrupt;
				}
				else
				{
          			`LOG("DARK VIP GENDER MISMATCH FOR :: " $RaiderUnit_State.GetMyTemplateName() @" :: "$GetGenderString(kSoldier.kAppearance.iGender) @" :: |X| :: "$GetGenderString(CharacterPool[cp].kAppearance.iGender) @" :: Pool :: " $CharacterPool[cp].GetName(eNameType_FullNick), default.bEnableRUMLog ,'RaiderUniformManager');
                } 
			} 
		}
    }

    //unit was on the right team, but has neither config or pool options
	`LOG("NO MATCHES FOUND FOR :: " $RaiderUnit_State.GetMyTemplateName(), default.bEnableRUMLog ,'RaiderUniformManager');
   	`LOG("ABORTED MANAGED UNIFORM CHANGE :: " $RaiderUnit_State.GetMyTemplateName(), default.bEnableRUMLog ,'RaiderUniformManager');

    //destroy any lingering char gens and kSoldiers ?
    if( CharGen != none )   {   CharGen.Destroy(); }

    `LOG("========================= RUM ENDED ==============================================", default.bEnableRUMLog ,'RaiderUniformManager');
    return ELR_NoInterrupt;
}

//////////////////////////////////////////////////
//  UNIFORM SWAPPER ON SUCCESSFUL FIND
/////////////////////////////////////////////////

static function SwapUniform( out XComGameState_Unit RaiderUnit_State, TSoldier kSoldier, XGCharacterGenerator CharGen, optional XComGameState GameState)
{
   	local XComUnitPawn          RaiderPawn;
	local XGUnit                RaiderUnit;
	local XComGameState_Item	WeaponState;

    //woo hoo we made it !! We should have a unit, a temporary doll-ksoldier, the correct gender, and a matching config or pool entry
    //actually set the new appearance
   	//	refreshes the pawn so that new appearance takes effect
	//	thanks to Mr. Nice and robojumper and xymanek for this! <> && <> Iridar

    RaiderUnit_State.SetCountry(kSoldier.nmCountry);
    RaiderUnit_State.SetTAppearance(kSoldier.kAppearance);

    RaiderUnit = XGUnit(`XCOMHISTORY.GetVisualizer(RaiderUnit_State.ObjectID));
    RaiderPawn = RaiderUnit.GetPawn();

    //	if there's a game state passed, it means we're patching raider appearance right during the mission load/start   //	so we need to re-Init their pawn and weapon.
	if (RaiderPawn != None && RaiderUnit != none && GameState != none)	
	{															
   	    `LOG("REFRESHING PAWN FOR UNIT :: " $RaiderUnit_State.GetMyTemplateName(), default.bEnableRUMLog ,'RaiderUniformManager');

		RaiderUnit.Uninit();
		
		RaiderPawn.SetAppearance(RaiderUnit_State.kAppearance);
		
		RaiderUnit.Init(RaiderUnit.GetPlayer(), RaiderUnit.GetSquad(), RaiderUnit_State);

		WeaponState = RaiderUnit_State.GetItemInSlot(eInvSlot_PrimaryWeapon);
		XGWeapon(WeaponState.FindOrCreateVisualizer(GameState)).Init(WeaponState);
	}

   	`LOG("SUCCESSFULLY MANAGED UNIFORM CHANGE :: " $RaiderUnit_State.GetMyTemplateName(), default.bEnableRUMLog ,'RaiderUniformManager');

    //destroy any lingering char gens and kSoldiers ?
    if( CharGen != none )   {   CharGen.Destroy(); }

    `LOG("========================= RUM ENDED ==============================================", default.bEnableRUMLog ,'RaiderUniformManager');
}

//////////////////////////////////////////////////
//  HELPER FUNCS - MAINLY FOR THE LOGGING
/////////////////////////////////////////////////

static function String GetGenderString(int GenderToConvert)
{
    switch (GenderToConvert)
    {
        case eGender_Female:    case 2:	return "FEMALE";
        case eGender_Male:      case 1:	return "MALE";
        default:                return "UNKNOWN :: INT " $GenderToConvert ;
            break;
    }
}

static function String GetTeamString(ETeam TeamToConvert)
{
	switch( TeamToConvert )
	{
		case eTeam_None:		return "NONE, RULER or CHOSEN";
		case eTeam_All:			return "ALL";
        case eTeam_XCom:		return "XCOM";
        case eTeam_Alien:		return "ADVENT";
        case eTeam_TheLost:		return "LOST";
        case eTeam_Neutral:		return "CIVS";
        case eTeam_Resistance:  return "RESISTANCE";
        case eTeam_One:         return "FACTION ONE";
        case eTeam_Two:         return "FACTION TWO";
        default:        		return "UNKNOWN :: ENUM " $TeamToConvert ;
            break;
	}
}
