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
using Rests;
using Terraria;
using TShockAPI;
using TShockAPI.DB;

namespace WhiteLotus
{
    [APIVersion(1, 13)]
    public class WhiteLotus : TerrariaPlugin
    {
        private UserManager userManager;
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
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
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

        private void SteamBan(CommandArgs args)
        {
            if (args.Parameters.Count < 1)
            {
                args.Player.SendInfoMessage("Usage: /steamban {steamid/steam64/username}");
                args.Player.SendInfoMessage("       valid steamid takes the form 'STEAM_X:X:X'");
                return;
            }

            Match m = Regex.Match(args.Parameters[0], "^STEAM_\\d:(\\d+):(\\d+)$");

            Int64 steamid64 = 0;
            if (m.Success)
            {
                Int32 authid = 0;
                if (!Int32.TryParse(m.Groups[2].Value, out authid))
                {
                    args.Player.SendErrorMessage("Users steamid is not valid: {0}", m.Groups[2].Value);
                    return;
                }

                Int32 server = 0;
                if (!Int32.TryParse(m.Groups[1].Value, out server))
                {
                    args.Player.SendErrorMessage("Users steamid is not valid: {0}", m.Groups[1].Value);
                    return;
                }

                Int64 stm64 = authid*2;
                stm64 += 76561197960265728;
                stm64 += server;
                steamid64 = stm64;
            }
            else
            {
                string steamid;
                try
                {
                    steamid = userManager.GetSteamIDForUsername(args.Parameters[0]);

                    if (!Int64.TryParse(steamid, out steamid64))
                    {
                        args.Player.SendErrorMessage("Users steam64 is not valid: {0}", steamid);
                        return;
                    }
                }
                catch (UserException e)
                {
                    args.Player.SendErrorMessage("SQL Error: {0}", e.Message);
                }
            }

            //do the ban with their wonderful steam64
            var accounts = new List<SteamUser>();
            try
            {
                accounts = userManager.GetUserAccounts(steamid64.ToString());
                userManager.Ban(steamid64.ToString());

                foreach (var acc in accounts)
                {
                    TShock.Bans.AddBan("", acc.UserAccountName, "Steam ban");
                }
            }
            catch (UserException e)
            {
                args.Player.SendErrorMessage("SQL Error: {0}", e.Message);
            }

            //ADD ban on the webend
            /*using (var cl = new WebClient())
            {
                string res = cl.UploadString("whitelotus.tshock.co/api/steam/ban", String.Format("steamid={0}&token={1}", steamid64, "token"));
                Console.WriteLine(res);
            }*/
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
}
