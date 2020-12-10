class SwatMPVotingPanel extends SwatGUIPanel
    Config(SwatGui);

import enum EMPMode from Engine.Repo;

var(SWATGui) private EditInline Config GUIListBox TeamMembers;

var(SWATGui) private EditInline Config GUIButton KickButton;
var(SWATGui) private EditInline Config GUIButton BanButton;
var(SWATGui) private EditInline Config GUIButton LeaderButton;

var(SWATGui) private EditInline Config GUIListBox MapList;
var(SWATGui) private EditInline Config GUIButton MapButton;
var(SWATGui) private EditInline Config GUIButton NextMapButton;
var(SWATGui) private EditInline Config GUIButton EndMapButton;
var(SWATGui) private EditInline Config GUIButton RestartMapButton;
var(SWATGui) private EditInline Config GUIButton StartMapButton;

var(SWATGui) private EditInline Config GUILabel ReferendumDetails;
var(SWATGui) private EditInline Config GUIButton VoteYesButton;
var(SWATGui) private EditInline Config GUIButton VoteNoButton;

var(SWATGui) private EditInline Config GUIButton BackgroundLeft;
var(SWATGui) private EditInline Config GUIButton BackgroundRight;
var(SWATGui) private EditInline Config GUIButton BackgroundCenter;

var(SWATGui) private EditInline Config GUIButton LoadMapsButton;

var(DEBUG) private GUIList FullMapList;

var private bool bPrevEnabled;

function InitComponent(GUIComponent MyOwner)
{
	super.InitComponent(MyOwner);

	FullMapList = GUIList(AddComponent("GUI.GUIList", self.Name$"_FullMapList", true ));

    LoadFullMapList();

	KickButton.OnClick = OnPlayerReferendumClicked;
	BanButton.OnClick = OnPlayerReferendumClicked;
	LeaderButton.OnClick = OnPlayerReferendumClicked;

	MapButton.OnClick = OnMapButtonClicked;

	NextMapButton.OnClick = OnSimpleReferendumClicked;
	EndMapButton.OnClick = OnSimpleReferendumClicked;
	RestartMapButton.OnClick = OnSimpleReferendumClicked;
	StartMapButton.OnClick = OnSimpleReferendumClicked;

	VoteYesButton.OnClick = OnVoteYesClicked;
	VoteNoButton.OnClick = OnVoteNoClicked;

  LoadMapsButton.OnClick = OnLoadMapsClicked;
}

private function LoadFullMapList()
{
	local LevelSummary Summary;
	local string FileName;

    FullMapList.Clear();

    foreach FileMatchingPattern( "*.s4m", FileName )
    {
        //skip autoplay files (auto generated by UnrealEd)
        if( InStr( FileName, "autosave" ) != -1 )
            continue;

        //remove the extension
        if(Right(FileName, 4) ~= ".s4m")
			FileName = Left(FileName, Len(FileName) - 4);

        Summary = Controller.LoadLevelSummary(FileName$".LevelSummary");

        if( Summary == None )
        {
            log( "WARNING: Could not load a level summary for map '"$FileName$".s4m'" );
        }
        else
        {
            FullMapList.Add( FileName, Summary, Summary.Title );
        }
    }
}

event Timer()
{
	// Update the team members list every second
    InitialiseTeamMembers();

	// Modify the voting display based on the state of the current referendum
	SetVotingEnabled();
}

private function SetVotingEnabled(optional bool bForceRefresh)
{
	local SwatGameReplicationInfo SGRI;
	local ServerSettings Settings;
	local bool bEnabled;

	SGRI = SwatGameReplicationInfo(PlayerOwner().GameReplicationInfo);
	Settings = ServerSettings(PlayerOwner().Level.CurrentServerSettings);

	if (SGRI == None || SGRI.RefMgr == None)
	{
		bEnabled = true;
	}
	else
	{
		bEnabled = !SGRI.RefMgr.ReferendumActive();
	}

	if (bEnabled != bPrevEnabled || bForceRefresh)
	{
		TeamMembers.SetVisibility(bEnabled);
		TeamMembers.SetEnabled(bEnabled);

		KickButton.SetVisibility(bEnabled);
		KickButton.SetEnabled(bEnabled);

		BanButton.SetVisibility(bEnabled);
		BanButton.SetEnabled(bEnabled);

		LeaderButton.SetVisibility(bEnabled && SGRI.Level.IsPlayingCOOP && !Settings.bNoLeaders);
		LeaderButton.SetEnabled(bEnabled && SGRI.Level.IsPlayingCOOP && !Settings.bNoLeaders);

		MapList.SetVisibility(bEnabled);
		MapList.SetEnabled(bEnabled);

		MapButton.SetVisibility(bEnabled);
		MapButton.SetEnabled(bEnabled);

        NextMapButton.SetVisibility(bEnabled);
        NextMapButton.SetEnabled(bEnabled);

        EndMapButton.SetVisibility(bEnabled);
        EndMapButton.SetEnabled(bEnabled);

        RestartMapButton.SetVisibility(bEnabled);
        RestartMapButton.SetEnabled(bEnabled);

		StartMapButton.SetVisibility(bEnabled);
		StartMapButton.SetEnabled(bEnabled);

		BackgroundLeft.SetVisibility(bEnabled);
		BackgroundRight.SetVisibility(bEnabled);

		ReferendumDetails.SetVisibility(!bEnabled);
		ReferendumDetails.SetEnabled(!bEnabled);

		VoteYesButton.SetVisibility(!bEnabled);
		VoteYesButton.SetEnabled(!bEnabled);

		VoteNoButton.SetVisibility(!bEnabled);
		VoteNoButton.SetEnabled(!bEnabled);

		BackgroundCenter.SetVisibility(!bEnabled);

		bPrevEnabled = bEnabled;
	}

	if (!bEnabled)
		ReferendumDetails.SetCaption(SGRI.RefMgr.GetReferendumDescription() $ " - " $ SGRI.RefMgr.GetNumberOfYesVotes() $ "/" $ SGRI.RefMgr.GetNumberOfNoVotes());
}

private function InternalOnActivate()
{
	InitialiseTeamMembers();

	SetVotingEnabled(true);

	SetTimer(1.0, true);

    if(GC.SwatGameState == GAMESTATE_MidGame)
    {
        EndMapButton.Show();
        EndMapButton.EnableComponent();
    }
    else
    {
        EndMapButton.Hide();
        EndMapButton.DisableComponent();
    }

    if(GC.SwatGameState != GAMESTATE_PreGame)
    {
        RestartMapButton.Show();
        RestartMapButton.EnableComponent();
		StartMapButton.Hide();
		StartMapButton.DisableComponent();
    }
    else
    {
        RestartMapButton.Hide();
        RestartMapButton.DisableComponent();
		StartMapButton.Show();
		StartMapButton.EnableComponent();
    }

	if (SwatGUIController(Controller).coopcampaign)
	{
		MapList.Hide();
		MapList.DisableComponent();

		LoadMapsButton.Hide();
		LoadMapsButton.DisableComponent();

        MapButton.Hide();
		MapButton.DisableComponent();

        NextMapButton.Hide();
        NextMapButton.DisableComponent();
	}
	else
	{
		MapList.Show();
		MapList.EnableComponent();

        MapButton.Show();
		MapButton.EnableComponent();

		LoadMapsButton.Show();
		LoadMapsButton.EnableComponent();

        NextMapButton.Show();
        NextMapButton.EnableComponent();
	}
}

private function InternalOnDeActivate()
{
    KillTimer();
}

private function InitialiseTeamMembers()
{
	local String CurrentSelection;
	local int LocalPlayerTeamNumber;
	local SwatGameReplicationInfo SGRI;
	local SwatPlayerReplicationInfo PlayerInfo;
	local int i;

	CurrentSelection = TeamMembers.List.Get();

	TeamMembers.List.Clear();

	// Do nothing if we don't have access to the local players team data
	if (PlayerOwner() == None || PlayerOwner().PlayerReplicationInfo == None || NetTeam(PlayerOwner().PlayerReplicationInfo.Team) == None)
		return;

	LocalPlayerTeamNumber = NetTeam(PlayerOwner().PlayerReplicationInfo.Team).GetTeamNumber();

	SGRI = SwatGameReplicationInfo(PlayerOwner().GameReplicationInfo);

    if (SGRI == None)
        return;

	// Fill the team members list with the player names of the local players team members
	for (i = 0; i < ArrayCount(SGRI.PRIStaticArray); ++i)
    {
        PlayerInfo = SGRI.PRIStaticArray[i];

        if (PlayerInfo != None)
        {
			if (PlayerOwner().Level.IsPlayingCOOP ||
				(NetTeam(PlayerInfo.Team) != None && NetTeam(PlayerInfo.Team).GetTeamNumber() == LocalPlayerTeamNumber))
			{
				TeamMembers.List.Add(PlayerInfo.PlayerName);
			}
		}
	}

	// Keep the current selection intact
	if (CurrentSelection != "")
		TeamMembers.List.Find(CurrentSelection); // Find will select the item if it finds it :/
}

private function InitialiseMapList()
{
    local int i, j;
    local LevelSummary Summary;

    MapList.Clear();

    for( i = 0; i < FullMapList.ItemCount; i++ )
    {
        Summary = LevelSummary( FullMapList.GetObjectAtIndex(i) );

        for( j = 0; j < Summary.SupportedModes.Length; j++ )
        {
            if( Summary.SupportedModes[j] == EMPMode.MPM_COOP )
            {
                MapList.List.AddElement( FullMapList.GetAtIndex(i) );
                break;
            }
        }
    }

    MapList.List.Sort();
	MapList.List.SetIndex(0);
}

private function OnLoadMapsClicked(GUIComponent Sender)
{
  InitialiseMapList();
}

private function OnPlayerReferendumClicked(GUIComponent Sender)
{
  local class<Voting.Referendum> Referendum;
  local String ReferendumTarget;

  ReferendumTarget = TeamMembers.List.Get();

  if(ReferendumTarget == "")
    return;

  if(SwatPlayerController(PlayerOwner()) == None)
    return;

  switch(Sender)
  {
    case KickButton:
      Referendum = class'SwatGame.KickReferendum';
      break;
    case BanButton:
      Referendum = class'SwatGame.BanReferendum';
      break;
    case LeaderButton:
      Referendum = class'SwatGame.LeaderReferendum';
      break;
  }

  SwatPlayerController(PlayerOwner()).ServerStartReferendumForPlayer(PlayerOwner(), Referendum, ReferendumTarget);

  if (SwatMPPage(Controller.TopPage()) != None)
		SwatMPPage(Controller.TopPage()).ResumeGame();
}

private function OnSimpleReferendumClicked(GUIComponent Sender)
{
	local class<Voting.Referendum> Referendum;

	if(SwatPlayerController(PlayerOwner()) == None)
	    return;

	switch(Sender)
	{
	    case EndMapButton:
	      	Referendum = class'SwatGame.EndMapReferendum';
	      	break;
	    case NextMapButton:
	      	Referendum = class'SwatGame.NextMapReferendum';
	      	break;
		case RestartMapButton:
		    Referendum = class'SwatGame.RestartLevelReferendum';
		    break;
		case StartMapButton:
			Referendum = class'SwatGame.StartMapReferendum';
			break;
	}

	SwatPlayerController(PlayerOwner()).ServerStartReferendum(PlayerOwner(), Referendum);

	if (SwatMPPage(Controller.TopPage()) != None)
		SwatMPPage(Controller.TopPage()).ResumeGame();
}

private function OnMapButtonClicked(GUIComponent Sender)
{
	local String MapName;

	MapName = MapList.List.Get();

	if (MapName == "")
		return;

	if (SwatPlayerController(PlayerOwner()) == None)
		return;

	SwatPlayerController(PlayerOwner()).ServerStartReferendum(PlayerOwner(), class'SwatGame.MapChangeReferendum', None, MapName);

	if (SwatMPPage(Controller.TopPage()) != None)
		SwatMPPage(Controller.TopPage()).ResumeGame();
}

private function OnVoteYesClicked(GUIComponent Sender)
{
	if (SwatPlayerController(PlayerOwner()) == None)
		return;

	SwatPlayerController(PlayerOwner()).ServerVoteYes();
}

private function OnVoteNoClicked(GUIComponent Sender)
{
	if (SwatPlayerController(PlayerOwner()) == None)
		return;

	SwatPlayerController(PlayerOwner()).ServerVoteNo();
}

defaultproperties
{
	OnActivate=InternalOnActivate
	OnDeactivate=InternalOnDeActivate
}