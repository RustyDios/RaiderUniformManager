//---------------------------------------------------------------------------------------
//  FILE:   UISL_RUM_NameExtender.uc                                    
//
//	CREATED BY RustyDios
//           
//	File created	31/08/20	12:00
//	LAST UPDATED    25/12/20	01:30
//  
//	Heavily inspired by https://steamcommunity.com/sharedfiles/filedetails/?id=715700207 Longer Names v2 by krj12
//
//---------------------------------------------------------------------------------------
class UISL_RUM_NameExtender extends UIScreenListener config(RaiderCustomization);

var config int iMaxCharacters;	//42

event OnInit(UIScreen Screen)
{

	local UIInputDialogue uiInputDialogue;
	local XComCharacterCustomization customizeManager;
	local bool bFailsafe;

	uiInputDialogue = UIInputDialogue(Screen);
	customizeManager = uiInputDialogue.Movie.Pres.GetCustomizeManager();
	
	if( uiInputDialogue.SteamInput == none )
	{
		if (   uiInputDialogue.m_kData.strTitle == customizeManager.CustomizeFirstName 
			|| uiInputDialogue.m_kData.strTitle == customizeManager.CustomizeLastName 
			|| uiInputDialogue.m_kData.strTitle == customizeManager.CustomizeNickName 
			|| uiInputDialogue.m_kData.strTitle == customizeManager.CustomizeWeaponName
			|| uiInputDialogue.m_kData.strTitle == "Weapon Name"
		   ) 
		{
			uiInputDialogue.SetData(uiInputDialogue.m_kData.strTitle, default.iMaxCharacters, uiInputDialogue.m_kData.strInputBoxText, uiInputDialogue.m_kData.DialogType, uiInputDialogue.m_kData.bIsPassword);
		}

		//failsafe fallback
		if ( uiInputDialogue.m_kData.iMaxChars < default.iMaxCharacters) 
        {
			bFailsafe = true;
			uiInputDialogue.m_kData.iMaxChars = default.iMaxCharacters;
            uiInputDialogue.SetData(uiInputDialogue.m_kData.strTitle, default.iMaxCharacters, uiInputDialogue.m_kData.strInputBoxText, uiInputDialogue.m_kData.DialogType, uiInputDialogue.m_kData.bIsPassword);
        }

		`LOG("strTitleWas :: " @uiInputDialogue.m_kData.strTitle @" :: Max input set to :: " @uiInputDialogue.m_kData.iMaxChars @" :: Was Failsafe ::" @bFailsafe, class'X2EventListener_RaiderUniformManager'.default.bEnableRUMLog ,'RaiderUniformManager');
	}
}

defaultproperties
{
	ScreenClass=class'UIInputDialogue'
}
//1234567890123456789#1234567890123456789#12
//42 characters is not that long for input..
