using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Text;
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
