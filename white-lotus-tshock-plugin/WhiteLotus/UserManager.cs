using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Runtime.Remoting.Messaging;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using MySql.Data.MySqlClient;
using TShockAPI;
using TShockAPI.DB;

namespace WhiteLotus
{
    internal class UserManager
    {
        private readonly IDbConnection database;

        public UserManager(IDbConnection db)
        {
            database = db;
            var table = new SqlTable("users",
                new SqlColumn("steam64", MySqlDbType.VarChar, 64),
                new SqlColumn("username", MySqlDbType.VarChar, 32) {Primary = true, Unique = true},
                new SqlColumn("banned", MySqlDbType.Int32)
                );
            var creator = new SqlTableCreator(db,
                db.GetSqlType() == SqlType.Sqlite
                    ? (IQueryBuilder) new SqliteQueryCreator()
                    : new MysqlQueryCreator());
            creator.EnsureExists(table);
        }

        public void InsertUser(string steamid, string accountname)
        {
            try
            {
                if (
                    database.Query("INSERT INTO users (steam64, username, banned) VALUES (@0, @1, @2);", steamid,
                        accountname, 0) != 1)
                {
                    throw new UserException(string.Format("User {0} already exists.", accountname));
                }
            }
            catch (Exception e)
            {
                if (Regex.IsMatch(e.Message, "username.*not unique"))
                    throw new UserException(string.Format("User {0} already exists.", accountname));
                throw new UserException("InsertUser SQL returned an error (" + e.Message + ")", e);
            }
        }

        public List<SteamUser> GetUserAccounts(string steam64)
        {
            List<SteamUser> accounts = new List<SteamUser>();
            using (var reader = database.QueryReader("SELECT * FROM users WHERE steam64 = @0", steam64))
            {
                while (reader.Read())
                {
                    SteamUser user = new SteamUser();
                    user.Steam64 = reader.Get<String>("steam64");
                    user.UserAccountName = reader.Get<String>("username");
                    user.Banned = (reader.Get<Int32>("banned") != 0);

                    accounts.Add(user);
                }
            }

            return accounts;
        }

    }

    class SteamUser
    {
        public String Steam64 { get; set; }
        public String UserAccountName { get; set; }
        public bool Banned { get; set; }
    }

    class UserException : Exception
    {
        public UserException(string m) : base(m)
        {
        }

        public UserException(string m, Exception e)
            : base(m, e)
        {
        }
    }
}
