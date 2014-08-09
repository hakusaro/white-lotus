using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using HttpServer;
using Mono.Data.Sqlite;
using MySql.Data.MySqlClient;
using Newtonsoft.Json;
using Rests;
using Terraria;
using TShockAPI;
using TShockAPI.DB;
using TerrariaApi.Server;
using white_lotus;

namespace WhiteLotus
{
    [ApiVersion(1, 16)]
    public class WhiteLotus : TerrariaPlugin
    {
        private UserManager userManager;
    	private Config Config;
        public WhiteLotus(Main game) : base(game)
        {
            Order = 10;
        }

        public override string Author
        {
            get
            {
                return "Nyx Studios";
            }
        }

        public override string Name
        {
            get
            {
                return "White Lotus";
            }
        }

        public override Version Version
        {
            get
            {
                return new Version(1, 0, 0, 0);
            }
        }

        public override void Initialize()
        {
            userManager = new UserManager(SetupDB());
            
            TShockAPI.Commands.ChatCommands.Add(new Command("white-lotus", SteamBan, "steamban"));

            TShock.RestApi.Register(new SecureRestCommand("/steam/user/add", AddUser, "white-lotus"));
            TShock.RestApi.Register(new SecureRestCommand("/steam/user/get", GetAccountsForSteam64, "white-lotus"));
            TShock.RestApi.Register(new SecureRestCommand("/steam/ban/create", SteamBanCreate, "white-lotus"));
            TShock.RestApi.Register(new SecureRestCommand("/steam/ban/delete", SteamBanDelete, "white-lotus"));
        	TShockAPI.Hooks.PlayerHooks.PlayerPostLogin += LookUpUser;

			if(!File.Exists(Path.Combine(TShock.SavePath, "white-lotus.json")))
				new Config().Write(Path.Combine(TShock.SavePath, "white-lotus.json"));
        	Config = Config.Read(Path.Combine(TShock.SavePath, "white-lotus.json"));
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
				TShockAPI.Hooks.PlayerHooks.PlayerPostLogin -= LookUpUser;
            }
            base.Dispose(disposing);
        }

        private IDbConnection SetupDB()
        {
            IDbConnection db;
            if (TShock.Config.StorageType.ToLower() == "sqlite")
            {
                string sql = Path.Combine(TShock.SavePath, "whitelotus.sqlite");
                db = new SqliteConnection(string.Format("uri=file://{0},Version=3", sql));
            }
            else if (TShock.Config.StorageType.ToLower() == "mysql")
            {
                try
                {
                    var hostport = TShock.Config.MySqlHost.Split(':');
                    db = new MySqlConnection();
                    db.ConnectionString =
                        String.Format("Server={0}; Port={1}; Database={2}; Uid={3}; Pwd={4};",
                                      hostport[0],
                                      hostport.Length > 1 ? hostport[1] : "3306",
                                      "whitelotus",
                                      TShock.Config.MySqlUsername,
                                      TShock.Config.MySqlPassword
                            );
                }
                catch (MySqlException ex)
                {
                    Log.Error(ex.ToString());
                    throw new Exception("MySql not setup correctly");
                }
            }
            else
            {
                throw new Exception("Invalid storage type");
            }
            return db;
        }

        private object AddUser(RestVerbs verbs, IParameterCollection parameters, SecureRest.TokenData tokenData)
        {
            string steamid = parameters["steamid"];
            string accountname = parameters["username"];

            if (string.IsNullOrWhiteSpace(steamid))
            {
                return RestMissingParam("steamid");
            }

            if (string.IsNullOrWhiteSpace(accountname))
            {
                return RestMissingParam("username");
            }

            try
            {
                userManager.InsertUser(steamid, accountname);
            }
            catch (UserException e)
            {
                return RestError(e.Message);
            }

            return new RestObject("200"){Response = "Successfully added user"};
        }

        private object GetAccountsForSteam64(RestVerbs verbs, IParameterCollection parameters, SecureRest.TokenData tokenData)
        {
            string steamid = parameters["steamid"];

            if (string.IsNullOrWhiteSpace(steamid))
            {
                return RestMissingParam("steamid");
            }

            var accounts = new List<SteamUser>();
            try
            {
                accounts = userManager.GetUserAccounts(steamid);
            }
            catch (UserException e)
            {
                return RestError(e.Message);
            }

            return new RestObject("200") {{"users", accounts}};
        }

        private object SteamBanCreate(RestVerbs verbs, IParameterCollection parameters, SecureRest.TokenData tokenData)
        {
            var steamid = parameters["steamid"];
            var reason = parameters["reason"];

            if (string.IsNullOrWhiteSpace(reason))
            {
                reason = "Steam ban";
            }

            Int64 steamid64 = -1;
            if (!LookupSteam64FromSteamid(steamid, out steamid64))
            {
                return RestError("Invalid steamid.  Valid steamids are STEAM_X:X:X or Steam64 ids.");
            }

            try
            {
                DoBan(steamid64.ToString(), "add", reason);
            }
            catch (UserException e)
            {
                return RestError(String.Format("SQL Error: {0}", e.Message));
            }

            return new RestObject("200") { Response = "Successfully banned user" };
        }

        private object SteamBanDelete(RestVerbs verbs, IParameterCollection parameters, SecureRest.TokenData tokenData)
        {
            var steamid = parameters["steamid"];

            Int64 steamid64 = -1;
            if (!LookupSteam64FromSteamid(steamid, out steamid64))
            {
                return RestError("Invalid steamid.  Valid steamids are STEAM_X:X:X or Steam64 ids.");
            }

            try
            {
                DoBan(steamid64.ToString(), "del", "");
            }
            catch (UserException e)
            {
                return RestError(String.Format("SQL Error: {0}", e.Message));
            }

            return new RestObject("200") { Response = "Successfully unbanned user" };
        }

        private void SteamBan(CommandArgs args)
        {
            if (args.Parameters.Count < 2)
            {
                args.Player.SendInfoMessage("Usage: /steamban {add/del} {steamid/steam64/username} [reason for ban]");
                args.Player.SendInfoMessage("       valid steamid takes the form 'STEAM_X:X:X', or the one seen on community profiles, or their name");
                args.Player.SendInfoMessage("       reason is optional and is inserted into the tshock ban table");
                return;
            }

            string mode = args.Parameters[0];
            string lookup = args.Parameters[1];
            Int64 steamid64 = 1;
            try
            {
                if (!LookupSteamId(lookup, out steamid64))
                {
                    args.Player.SendErrorMessage("Users steam64 is not valid: {0}", lookup);
                    return;
                }
            }
            catch (UserException e)
            {
                args.Player.SendErrorMessage("SQL Error: {0}", e.Message);
                return;
            }

            string reason = "Steam ban";

            if (mode.ToUpper().Equals("ADD") && (args.Parameters.Count > 1))
            {
                reason = string.Join(" ", args.Parameters, 2, args.Parameters.Count - 2);
            }

            try
            {
                DoBan(steamid64.ToString(), mode, reason);

            	var action = mode.ToLower() == "add" ? "create" : "delete";

            	ThreadPool.QueueUserWorkItem(s =>
            	                             	{
            	                             		using (var cl = new WebClient())
            	                             		{
            	                             			var client =
            	                             				(HttpWebRequest)
            	                             				WebRequest.Create(
            	                             					String.Format("http://162.243.89.83:4567/ban/{0}/{1}/{2}/{3}",
            	                             					              action, steamid64.ToString(), Config.ServerId,
            	                             					              Config.RestToken));
            	                             			client.Timeout = 5000;
            	                             			try
            	                             			{
            	                             				using (var resp = GetResponseNoException(client))
            	                             				{
            	                             					if (resp.StatusCode != HttpStatusCode.OK)
            	                             					{
            	                             						throw new IOException("Server did not respond with an OK.");
            	                             					}
            	                             				}
            	                             			}
            	                             			catch (Exception e)
            	                             			{
            	                             				Console.Error.WriteLine(e.Message);
            	                             			}
            	                             		}
            	                             	});
            }
            catch (UserException e)
            {
                args.Player.SendErrorMessage("SQL Error: {0}", e.Message);
            }
        }

		private void LookUpUser(TShockAPI.Hooks.PlayerPostLoginEventArgs args)
		{
			ThreadPool.QueueUserWorkItem(s=>{
				try
				{
					var steamid = "";
					steamid = userManager.GetSteamIDForUsername(args.Player.UserAccountName);
					using (var cl = new WebClient())
					{
						var uri = String.Format("http://162.243.89.83:4567/user/lookup/{0}/{1}/{2}", steamid, Config.ServerId,
						                        Config.RestToken);
						var client = (HttpWebRequest)WebRequest.Create(uri);
						client.Timeout = 5000;
						try
						{
							using (var resp = GetResponseNoException(client))
							{
								if (resp.StatusCode != HttpStatusCode.OK)
								{
									throw new IOException("Server did not respond with an OK.");
								}

								using (var reader = new StreamReader(resp.GetResponseStream()))
								{
									var text = reader.ReadToEnd();
									var obj = JsonConvert.DeserializeObject<UserInfo>(text);
									if (Config.GlobalBansTriggerCount > 0 && obj.GlobalBans >= Config.GlobalBansTriggerCount)
									{
										DoBan(steamid, "Global auto ban", "add");
									}
									else if(Config.NotifyGlobalBans)
									{
										foreach(var ply in TShock.Players.ToList().Where(p=>p != null && p.IsLoggedIn && p.Group.HasPermission("white-lotus")))
										{
											ply.SendWarningMessage(
												String.Format("{0} has just logged in.  He is banned from {1} White Lotus servers.", 
												args.Player.UserAccountName, 
												obj.GlobalBans)
											);
										}
									}
								}
							}
						}
						catch (Exception e)
						{
							Console.Error.WriteLine(e.Message);
						}
					}
				}
				catch(Exception e)
				{
					Console.Error.WriteLine(e.Message);
				}
			});
		}

        private void DoBan(string steamid, string reason, string mode)
        {
            //do the ban with their wonderful steam64
            var accounts = new List<SteamUser>();
            accounts = userManager.GetUserAccounts(steamid);
            switch (mode.ToUpper())
            {
                case "ADD":
                    {
                        userManager.AddBan(steamid);

                        foreach (var acc in accounts)
                        {
                            TShock.Bans.AddBan("", acc.UserAccountName, "", reason, false, "white-lotus");
                        }
                        break;
                    }
                case "DEL":
                    {
                        userManager.DelBan(steamid);

                        foreach (var acc in accounts)
                        {
                            TShock.Bans.RemoveBan(acc.UserAccountName, true, false, false);
                        }
                        break;
                    }
            }
        }

        private bool LookupSteam64FromSteamid(string steam64, out Int64 steamid64)
        {
            Match m = Regex.Match(steam64, "^STEAM_\\d:(\\d+):(\\d+)$");

            steamid64 = -1;
            if (m.Success)
            {
                Int32 authid = 0;
                Int32 server = 0;
                if (Int32.TryParse(m.Groups[2].Value, out authid) && Int32.TryParse(m.Groups[1].Value, out server))
                {
                    Int64 stm64 = authid * 2;
                    stm64 += 76561197960265728;
                    stm64 += server;
                    steamid64 = stm64;
                }
                else
                {
                    steamid64 = -1;
                }

                return true;
            }

            return false;
        }

        private bool LookupSteamId(string lookup, out Int64 steamid64)
        {
            if (!LookupSteam64FromSteamid(lookup, out steamid64))
            {
                string steamid = userManager.GetSteamIDForUsername(lookup);
                if (!Int64.TryParse(steamid, out steamid64))
                {
                    steamid64 = -1;
                }
            }

            return steamid64 != -1;
        }

		private HttpWebResponse GetResponseNoException(HttpWebRequest req)
		{
			try
			{
				return (HttpWebResponse)req.GetResponse();
			}
			catch (WebException we)
			{
				var resp = we.Response as HttpWebResponse;
				if (resp == null)
					throw;
				return resp;
			}
		}

        private RestObject RestMissingParam(string var)
        {
            return RestError("Missing or empty " + var + " parameter");
        }

        private RestObject RestError(string message, string status = "400")
        {
            return new RestObject(status) { Error = message };
        }
    }

	class UserInfo
	{
		public int GlobalBans { get; set; }
	}
}
