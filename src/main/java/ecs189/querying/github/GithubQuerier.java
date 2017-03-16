package ecs189.querying.github;

import ecs189.querying.Util;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.net.URL;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/**
 * Created by Vincent on 10/1/2017.
 */
public class GithubQuerier {

    private static final String BASE_URL = "https://api.github.com/users/";

    // Used for filtering different event types
    private static final String PUSH_EVENT = "PushEvent";
    private static final String FORK_EVENT = "ForkEvent";

    private static final String ACCESS_TOKEN = "3ffe1ab05520e4ce482919610399a7c97284e28c";

    public static String eventsAsHTML(String user) throws IOException, ParseException {
        // Get all the relevant events that we are interested in
        List<JSONObject> response = getEvents(user, PUSH_EVENT);

        StringBuilder sb = new StringBuilder();
        sb.append("<div>");
        for (int i = 0; i < response.size(); i++) {
            JSONObject event = response.get(i);
            // Get event type
            String type = event.getString("type");
            // Get created_at date, and format it in a more pleasant style
            String creationDate = event.getString("created_at");
            SimpleDateFormat inFormat = new SimpleDateFormat("yyyy-MM-dd'T'hh:mm:ss'Z'");
            SimpleDateFormat outFormat = new SimpleDateFormat("dd MMM, yyyy");
            Date date = inFormat.parse(creationDate);
            String formatted = outFormat.format(date);

            // Get the Payload as a JSONObject
            JSONObject payload = event.getJSONObject("payload");
            JSONArray commitArray = payload.getJSONArray("commits");

            // Make sure that there are actually valid commits in this entry
            if (commitArray.length() == 0)
                continue;

            // Wrap this particular event's info in a container
            sb.append("<div class=\"container\">");
                // And for stylistic purposes, a jumbotron
                sb.append("<div class=\"jumbotron eventJumbo\">");

                    // Use Bootstrap's grid system for positioning the elements properly
                    sb.append("<div class=\"row\">");

                        // Three columns by themselves
                        sb.append("<div class=\"col-md-3\"></div>");

                        // And three for the event label
                        sb.append("<div class=\"col-md-4\" id=\"typeCol\">");

                            // Add type of event as header
                            sb.append("<span class=\"type withLatoBlack\">");

                                // Adapt text according to the type it is
                                String userFriendlyTypeLabel;
                                String fullRepoName = event.getJSONObject("repo").getString("name");

                                // If the repo name (along with the account name) is too long, shorten it so that it properly displays
                                String accountName = fullRepoName.substring(0, fullRepoName.indexOf("/"));
                                String repoName =  fullRepoName.substring(fullRepoName.indexOf("/") + 1);

                                String finalRepoName;
                                if (accountName.length() + repoName.length() > 23) {
                                    accountName = accountName.charAt(0) + "...";
                                    if (repoName.length() + 4 > 23) {
                                        repoName = repoName.substring(0, 15) + "...";
                                    }
                                }

                                finalRepoName = accountName + "/" + repoName;

                                if (type.equals(PUSH_EVENT)) {
                                    userFriendlyTypeLabel = "Pushed <span class=\"withLatoLight\">to</span> " + "<span class=\"label label-primary\" id=\"repoLabel\">" + finalRepoName + "</span>";
                                } else {
                                    userFriendlyTypeLabel = "Unknown Type of Event.";
                                }
                                sb.append(userFriendlyTypeLabel);

                            sb.append("</span>");

                        // Close the above div
                        sb.append("</div>");

                        // And three for the time label
                        sb.append("<div class=\"col-md-4\" id=\"dateCol\">");

                            // Add formatted date
                            // Add type of event as header
                            sb.append("<span class=\"date withOxygenRegular\">");
                                sb.append("<span class=\"label label-default\">");
                                    sb.append(formatted);
                                sb.append("</span>");
                            sb.append("</span>");

                        // Close the above div
                        sb.append("</div>");

                        // The remaining three columns by themselves
                        sb.append("<div class=\"col-md-3\"></div>");

                    // Close the row div
                    sb.append("</div>");

                    if (type.equals(PUSH_EVENT)) {
                        // Now display the SHA hashes of the commits
                        sb.append("<hr class=\"commitIntroHR\">");
                        sb.append("<p class=\"withLatoRegular center\">Here are the commits associated with this push request:</p>");

                        // Initialize a table
                        sb.append("<table class=\"table table-bordered\">");
                            sb.append("<thead>");
                                sb.append("<tr>");
                                    sb.append("<th>SHA</th>");
                                    sb.append("<th>Email</th>");
                                    sb.append("<th>Message</th>");
                                sb.append("</tr>");
                            sb.append("</thead>");

                            sb.append("<tbody>");

                            for (int commitIndex = 0; commitIndex < commitArray.length(); commitIndex++) {
                                JSONObject thisCommit = commitArray.getJSONObject(commitIndex);
                                String shaOfCommit = thisCommit.getString("sha");
                                String urlOfCommit = thisCommit.getString("url");
                                String commitMsg = thisCommit.getString("message");
                                String authorOfCommit = thisCommit.getJSONObject("author").getString("email");

                                sb.append("<tr>");

                                    // The SHA part
                                    sb.append("<td>");

                                        sb.append("<p class=\"withMontserratRegular regularSizedText\"><a href=\"" + urlOfCommit + "\">");
                                        sb.append(shaOfCommit);
                                        sb.append("</a></p>");

                                    sb.append("</td>");

                                    // Now the email
                                    sb.append("<td>");

                                        sb.append("<p class=\"withLatoLight regularSizedText\">" + authorOfCommit + "</p>");

                                    sb.append("</td>");

                                    // And the Message
                                    sb.append("<td>");

                                        sb.append("<p class=\"regularSizedText\">" + commitMsg + "</p>");

                                    sb.append("</td>");

                                sb.append("</tr>");
                            }
                        }

                        sb.append("</tbody>");
                    sb.append("</table>");

                    // Add collapsible JSON textbox (don't worry about this for the homework; it's just a nice CSS thing I like)
                    sb.append("<div class=\"center\"><p id=\"rawJSONLbl\"><a data-toggle=\"collapse\" href=\"#event-" + i + "\">Raw JSON</a></p>");
                    sb.append("<div id=event-" + i + " class=\"collapse\" style=\"height: auto;\"> <pre>");
                    sb.append(event.toString());
                    sb.append("</pre> </div> </div>");

                // Close the jumbotron div
                sb.append("</div>");
            // And the container one as well
            sb.append("</div>");
        }
        sb.append("</div>");
        return sb.toString();
    }

    private static List<JSONObject> getEvents(String user, String... eventsToCapture) throws IOException {
        List<JSONObject> eventList = new ArrayList<JSONObject>();

        // Bool to keep track of whether the next page should be explored
        boolean continueTraversing = true;

        // Page number to traverse through - starting at 1
        int pageNum = 1;

        // Other initialization variables
        int numOfPushEvents = 0;
        boolean validType;

        while (numOfPushEvents < 10 && continueTraversing) {
            String url = BASE_URL + user + "/events";
            System.out.println(url);

            // Add the page number to the url
            url += "?page=" + pageNum;

            // If the access token is specified, make the request leveraging that
            if (!ACCESS_TOKEN.equals("")) {
                url = Util.appendAuthKey(url, ACCESS_TOKEN);
            }

            JSONObject json = Util.queryAPI(new URL(url));
            System.out.println(json);
            JSONArray events = json.getJSONArray("root");

            // Check to make sure that the JSON response was not empty
            if (events.length() == 0) {
                continueTraversing = false;
                break;
            }

            for (int eventIndex = 0; eventIndex < events.length(); eventIndex++) {
                JSONObject thisEvent = events.getJSONObject(eventIndex);
                String thisEventType = thisEvent.getString("type");
                validType = false;

                for (String eachRelevantType : eventsToCapture) {
                    if (eachRelevantType.equals(thisEventType)) {
                        validType = true;
                        break;
                    }
                }

                // Only select events that are relevant
                if (validType) {
                    eventList.add(thisEvent);
                    numOfPushEvents++;
                }
            }

            pageNum++;
        }
        return eventList;
    }
}