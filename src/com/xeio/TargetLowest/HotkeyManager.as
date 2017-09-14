import com.GameInterface.Game.TeamInterface;
import com.GameInterface.Game.CharacterBase;
import com.GameInterface.Game.Team;
import com.GameInterface.Game.Raid;
import com.GameInterface.Game.Character;
import com.GameInterface.Game.BuffData;
import com.GameInterface.Game.TargetingInterface;
import com.GameInterface.ProjectUtils;

class com.xeio.TargetLowest.HotkeyManager
{
	static var CORRUPTION_BUFFID:Number = 9257969;
	static var MARTYRDOM_BUFFID:Number = 9257968;
	static var ROLE_TANK:Number = ProjectUtils.GetUint32TweakValue("GroupFinder_Tank_Buff");
	
	static function ToggleFriendlyTarget()
	{
		if (TeamInterface.IsInRaid(CharacterBase.GetClientCharID()))
		{
			var raid:Raid = TeamInterface.GetClientRaidInfo();
			var lowestCharacter:Character = FindTargetForTeams(raid.m_Teams);
			TargetingInterface.SetTarget(lowestCharacter.GetID());
		}
		else if (TeamInterface.IsInTeam(CharacterBase.GetClientCharID()))
		{
			var teams = new Object();
			teams["team1"] = TeamInterface.GetClientTeamInfo();			
			var lowestCharacter:Character = FindTargetForTeams(teams);
			TargetingInterface.SetTarget(lowestCharacter.GetID());
		}
	}
	
	static function FindTargetForTeams(teams:Object):Character
	{
		var searchStatus:Object = new Object();
		searchStatus.characterWithLowestHP = undefined;
		searchStatus.lowestPercent = 999;
		searchStatus.lowestIsCorrupted = true;
		searchStatus.currentTargetIsTank = false;
		
		for (var key:String in teams)
		{
			SearchTeam(teams[key], searchStatus);
		}
		
		return searchStatus.characterWithLowestHP;
	}
	
	static function SearchTeam(team:Team, searchStatus:Object)
	{
		for (var teamMember in team.m_TeamMembers)
		{
			var character:Character = Character.GetCharacter(team.m_TeamMembers[teamMember].m_CharacterId);
			if (!character) continue;
			
			var hasHighCorruption:Boolean = false;
			var corruptedBuff:BuffData = character.m_InvisibleBuffList[CORRUPTION_BUFFID] || character.m_InvisibleBuffList[MARTYRDOM_BUFFID];
			if (corruptedBuff && corruptedBuff.m_Count > 90)
			{
				hasHighCorruption = true;
			}
			
			var maxHP = character.GetStat(_global.Enums.Stat.e_Life, 2);
			var currentHP = character.GetStat(_global.Enums.Stat.e_Health, 2);
			var percent = currentHP / maxHP;
			
			if (percent <= searchStatus.lowestPercent)
			{
				if (hasHighCorruption && searchStatus.lowestIsCorrupted)
				{
					searchStatus.characterWithLowestHP = character;
					searchStatus.lowestPercent = percent;
				}
				else
				{
					searchStatus.characterWithLowestHP = character;
					searchStatus.lowestPercent = percent;
					searchStatus.lowestIsCorrupted = false;
				}
			}
			
			if (character.m_BuffList[ROLE_TANK] != undefined || character.m_InvisibleBuffList[ROLE_TANK] != undefined)
			{
				if (searchStatus.lowestPercent == 1)
				{
					//Everyone is at max HP, set tank to target
					searchStatus.characterWithLowestHP = character;
					searchStatus.lowestPercent = percent;
					searchStatus.currentTargetIsTank = true;
				}
			}
		}
	}
}