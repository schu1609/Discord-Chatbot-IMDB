using System;
using System.Collections.Generic;
using System.Text;

namespace Chatbot
{
    class User
    {
        string name;
        string history;
        string id;
        string favoriteGenre;
        string language;
        string ConnectionUsers;
        public User(string id, string name, string language, string history = "nothing")
        {
            this.id = id;
            this.name = name;
            this.language = language;
            this.history = history;
        }
        private Boolean Watched()
        {
            return false;
        }
    }
}
